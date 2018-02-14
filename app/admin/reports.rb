ActiveAdmin.register Report do
  menu false
  permit_params :department_id, :email
  index do
    column :id
    column :email
    column :department
    actions
  end
end
