ActiveAdmin.register Client do
  permit_params :user_id, :first_name, :last_name, :phone_number, :notes
  index do
    column :user
    column :full_name
    column :phone_number
    column :active
    column :notes
    actions
  end

  actions :all, :except => [:destroy]

  filter :user
  filter :first_name, label: 'Client first name'
  filter :last_name, label: 'Client last name'
  filter :phone_number
  filter :active
  filter :notes_present, as: 'boolean'

  form do |f|
    f.inputs "Client Info" do
      f.input :user_id, :label => 'User', :as => :select, :collection => User.all.map { |user| ["#{user.full_name}", user.id] }
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :notes
    end

    f.actions
  end

  controller do
    def update
      previous_user_id = resource.user_id
      super do |success, failure|
        success.html do
          if params[:client][:user_id] != previous_user_id
            NotificationMailer.client_transfer_notification(
              current_user: resource.user,
              previous_user: User.find(previous_user_id),
              client: resource
            ).deliver_later
          end
          render :show
        end

        failure.html { render :edit }
      end
    end
  end
end
