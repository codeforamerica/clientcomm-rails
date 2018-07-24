ActiveAdmin.register FeatureFlag do
  menu priority: 4, parent: 'Manage'

  permit_params :flag, :enabled
  actions :edit, :update, :index

  index do
    column :flag
    column :enabled
    actions
  end

  form do |f|
    f.inputs do
      f.input :flag
      f.input :enabled
    end
    f.actions
  end
end
