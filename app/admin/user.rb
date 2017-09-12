ActiveAdmin.register User do
  permit_params :full_name, :email, :password, :password_confirmation
  index do
    selectable_column
    id_column
    column :full_name
    column :email

    actions defaults: true do |user|
      link_to 'Disable', disable_admin_user_path(user) if user.active
    end
  end

  actions :all, :except => [:destroy]

  member_action :disable, method: :get do
    @page_title = "Disable #{resource.full_name}'s account"
  end

  member_action :disable_confirm, method: :get do
    resource.update!(active: false)

    redirect_to admin_users_path
  end

  filter :email
  filter :full_name

  form do |f|
    f.inputs "User Info" do
      f.input :full_name
      f.input :email
      f.input :password
      f.input :password_confirmation
    end

    f.actions
  end
end
