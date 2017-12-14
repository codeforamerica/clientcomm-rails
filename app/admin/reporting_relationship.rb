ActiveAdmin.register ReportingRelationship do
  breadcrumb do
    [
      link_to('ADMIN', admin_root_path),
      link_to('CLIENTS', admin_clients_path),
      link_to(resource.client.full_name.upcase, admin_client_path(resource.client))
    ]
  end

  form title: 'Transfer Client' do |f|
    active_user = resource.user
    department = active_user.department
    department_users = department.users.active.order(full_name: :asc)
    options = options_from_collection_for_select(
      department_users,
      :id,
      :full_name,
      active_user.try(:id)
    )

    # f.input 'Transfer to', for: f.object.user.id,
    #   label: "#{department.name} user:",
    #   as: :select,
    #   collection: options,
    #   include_blank: true,
    #   input_html: { multiple: false, id: "user_in_dept_#{department.id}" }

    f.inputs 'Change user', for: f.object.user do |user|
      li do
        label 'Current user'
        span user.object.full_name
      end

      # user.input :full_name

      user.input :id, label: 'Transfer to',
                      as: :select,
                      collection: options,
                      include_blank: true,
                      input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
    end
  end
end
