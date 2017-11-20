ActiveAdmin.register Client do
  menu priority: 4

  config.sort_order = 'last_name_asc'

  permit_params :user_id, :first_name, :last_name, :phone_number, :notes, :active, :client_status_id
  index do
    selectable_column
    column :full_name, sortable: :last_name
    column 'Users' do |client|
      client.users.map do |user|
        user.full_name
      end.join('\n')
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
      # f.input :user_id, label: 'User', as: :select, collection: User.all.order(full_name: :asc).pluck(:full_name, :id), include_blank: false
      f.input :active, as: :radio unless f.object.new_record?
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :client_status if FeatureFlag.enabled?('client_status')
      f.input :notes
      Department.all.each do |department|
        f.input :users, {
          label: "User for #{department.name}",
          as: :select,
          collection: department.users.order(full_name: :asc).pluck(:full_name, :id),
          include_blank: true,
          input_html: { multiple: false }
        }
      end
    end

    f.actions
  end

  controller do
    def index
      params[:q][:phone_number_cont] = params[:q][:phone_number_cont].gsub(/\D/, '') if params[:q].try(:[], :phone_number_cont)

      super
    end

    def update
      # previous_user_id = resource.user_id
      super do |success, failure|
        success.html do
          # resource.messages.scheduled.update_all(user_id: params[:client][:user_id])
          # if params[:client][:user_id] != previous_user_id.to_s
          #   NotificationMailer.client_transfer_notification(
          #     current_user: resource.user,
          #     previous_user: User.find(previous_user_id),
          #     client: resource
          #   ).deliver_later
          # end
          render :show
        end

        failure.html { render :edit }
      end
    end
  end
end
