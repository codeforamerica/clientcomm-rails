ActiveAdmin.register User do
  menu priority: 3

  permit_params :full_name, :email, :phone_number, :password, :password_confirmation, :message_notification_emails
  index do
    column :full_name
    column :email
    column :phone_number
    column :active
    column :created_at

    actions defaults: true do |user|
      user.active ?
        link_to('Disable', disable_admin_user_path(user)) :
        link_to('Enable', enable_admin_user_path(user))
    end
  end

  actions :all, :except => [:destroy]

  member_action :disable, method: :get do
    @page_title = "Disable #{resource.full_name}'s account"
    @clients_to_disable = resource.clients.active
  end

  member_action :enable, method: :get do
    resource.update!(active: true)

    redirect_to admin_users_path
  end

  member_action :disable_confirm, method: :get do
    resource.update!(active: false)

    resource.reporting_relationships.active.update(active: false)

    redirect_to admin_users_path
  end

  filter :email
  filter :full_name

  show do
    panel 'View Clients' do
      link_to 'Clients', admin_clients_path(q: { user_id_eq: user.id })
    end

    panel 'User Details' do
      attributes_table_for user do
        row :full_name
        row :email
        row :phone_number
        row :active
        row :message_notification_emails
        row :current_sign_in_at
        row :current_sign_in_ip
        row :updated_at
        row :created_at
        row :reset_password_sent_at
      end
    end
  end

  form do |f|
    panel 'View Clients' do
      link_to 'Clients', admin_clients_path(q: { user_id_eq: user.id })
    end

    f.inputs 'User Info' do
      f.input :full_name
      f.input :email
      f.input :phone_number, label: 'Desk phone number'
      f.input :message_notification_emails, as: :radio unless f.object.new_record?

      if f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end
    end

    unless f.object.new_record?
      panel 'User Status' do
        user.active ?
            link_to('Disable', disable_admin_user_path(user)) :
            link_to('Enable', enable_admin_user_path(user))
      end
    end

    f.actions
  end
end
