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

  form do |f|
    f.inputs "Client Info" do
      f.input :user_id, :label => 'User', :as => :select, :collection => User.all.map{|user| ["#{user.full_name}", user.id]}
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :notes
    end

    f.actions
  end
end
