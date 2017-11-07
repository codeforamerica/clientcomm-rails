ActiveAdmin.register Client do
  menu priority: 4

  config.sort_order = 'last_name_asc'

  permit_params :user_id, :first_name, :last_name, :phone_number, :notes, :active, :client_status_id
  index do
    selectable_column
    column :full_name, sortable: :last_name
    column :user do |client|
      client.user.full_name
    end
    column :phone_number
    column :active
    column :client_status
    column :notes
    actions
  end

  action_item :bulk_import, only: :index { link_to 'Bulk Import', new_admin_import_csv_path }

  actions :all, :except => [:destroy]

  filter :user, collection: proc { User.all.order(full_name: :asc).pluck(:full_name, :id) }
  filter :first_name_cont, label: 'Client first name'
  filter :last_name_cont, label: 'Client last name'
  filter :phone_number_cont, label: 'Phone Number'
  filter :active
  filter :notes_present, as: 'boolean'

  form do |f|
    f.inputs 'Client Info' do
      f.input :user_id, label: 'User', as: :select, collection: User.all.order(full_name: :asc).pluck(:full_name, :id), include_blank: false
      f.input :active, as: :radio unless f.object.new_record?
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :client_status if FeatureFlag.enabled?('client_status')
      f.input :notes
    end

    f.actions
  end

  batch_action :transfer, form: -> { { user: User.all.order(full_name: :asc).pluck(:full_name, :id) } } do |ids, inputs|
    user = User.find(inputs[:user])
    number_of_clients = ids.length
    transferred_clients = []

    Client.find(ids).each do |client|
      previous_user_id = client.user.id
      client.update(user: user)
      client.messages.scheduled.update_all(user_id: user.id)

      if inputs[:user] != previous_user_id
        transferred_clients << { client: client, previous_user: User.find(previous_user_id) }
      end
    end

    NotificationMailer.batch_transfer_notification(
      current_user: user,
      transferred_clients: transferred_clients
    ).deliver_later

    analytics_track({
                      label: :client_transfer,
                      data: {
                        admin_id: current_admin_user.id,
                        clients_transferred_count: number_of_clients
                      }
                    })

    redirect_to admin_clients_path, alert: "Clients transferred: #{number_of_clients}."
  end

  controller do
    def index
      params[:q][:phone_number_cont] = params[:q][:phone_number_cont].gsub(/\D/, '') if params[:q].try(:[], :phone_number_cont)

      super
    end

    def update
      previous_user_id = resource.user_id
      super do |success, failure|
        success.html do
          resource.messages.scheduled.update_all(user_id: params[:client][:user_id])
          if params[:client][:user_id] != previous_user_id.to_s
            NotificationMailer.client_transfer_notification(
              current_user: resource.user,
              previous_user: User.find(previous_user_id),
              client: resource
            ).deliver_later

            analytics_track({
                              label: :client_transfer,
                              data: {
                                admin_id: current_admin_user.id,
                                clients_transferred_count: 1
                              }
                            })
          end
          render :show
        end

        failure.html { render :edit }
      end
    end
  end
end
