ActiveAdmin.register User do
  permit_params :full_name, :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    actions
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
