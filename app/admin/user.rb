ActiveAdmin.register User do
  menu priority: 2

  permit_params :full_name, :email, :password, :password_confirmation
  index do
    selectable_column
    column :full_name
    column :email
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
  end

  member_action :enable, method: :get do
    resource.update!(active: true)

    redirect_to admin_users_path
  end

  member_action :disable_confirm, method: :get do
    resource.update!(active: false)

    user = User.find_by_email!(ENV['UNCLAIMED_EMAIL'])
    resource.clients.where(active: false).each do |client|
      client.update!(user: user)
    end

    redirect_to admin_users_path
  end

  filter :email
  filter :full_name

  show do
    panel 'View Clients' do
      link_to 'Clients', admin_clients_path(q: {user_id_eq: user.id})
    end

    default_main_content
  end

  form do |f|
    f.inputs "User Info" do
      f.input :full_name
      f.input :email

      if f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end
    end

    panel 'User Status' do
      user.active ?
        link_to('Disable', disable_admin_user_path(user)) :
        link_to('Enable', enable_admin_user_path(user))
    end

    f.actions
  end
end
