ActiveAdmin.register Department do
  permit_params :user_id, :name, :phone_number

  form do |f|
    f.inputs do
      if resource.persisted?
        f.input :user_id, as: :select, collection: User.where(department: resource)
      end
      f.input :name
      f.input :phone_number
    end
    f.actions
  end

  controller do
    def destroy
      if resource.users.any?(&:active)
        flash[:error] = 'Cannot delete a department with active users.'
        redirect_back(fallback_location: admin_departments_path)
      else
        super
      end
    end
  end
end
