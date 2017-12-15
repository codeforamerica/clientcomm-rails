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
    f.inputs 'Change user', for: f.object.user do |u|
      u.input :department_id, as: :hidden
      # rubocop:disable Rails/OutputSafety
      u.template.concat "<li><label class='label'>Current user</label><span>#{f.object.user.full_name || '-'}</span></li>".html_safe
      u.input :id, label: 'Transfer to:',
                   as: :select,
                   collection: options,
                   include_blank: true,
                   input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
      u.template.concat "<li><label class='label' for='transfer_note'>Include a note for the new user</label><textarea id='transfer_note' name='transfer[note]'></textarea></li>".html_safe
      # rubocop:enable Rails/OutputSafety
    end
    f.actions do
      f.action :submit, as: :button, label: 'Transfer Client'
      f.action :cancel, label: 'Cancel', wrapper_html: { class: 'cancel' }
    end
  end

  controller do
    def update
      rr_id = params['id']
      target_user_id = params['reporting_relationship']['user']['id']
      transfer_note = params['transfer']['note']
      department_id = params['reporting_relationship']['user']['department_id']

      rr = ReportingRelationship.find(rr_id)

      new_user = User.find_by(id: target_user_id, department_id: department_id)

      previous_user = rr.user

      client = rr.client
      department = Department.find(department_id)

      if new_user == previous_user
        render(:new) && return # TODO: fix this
      end

      client.messages
            .scheduled
            .where(user: previous_user)
            .update(user_id: new_user)

      ReportingRelationship.where(client: client, user: department.users).each do |relationship|
        relationship.update!(active: false)
      end

      if new_user.blank?
        render(:new) && return # TODO: fix this
      end

      new_user.reporting_relationships.find_or_create_by(client: client).update!(active: true)

      NotificationMailer.client_transfer_notification(
        current_user: new_user,
        previous_user: previous_user,
        client: client,
        transfer_note: transfer_note
      ).deliver_later

      # TODO: uncomment
      # analytics_track(
      #   label: :client_transfer,
      #   data: {
      #     admin_id: current_admin_user.id,
      #     clients_transferred_count: 1
      #   }
      # )
    end
  end
end
