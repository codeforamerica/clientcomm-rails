ActiveAdmin.register ReportingRelationship do
  menu false

  breadcrumb do
    crumbs = [
      link_to('ADMIN', admin_root_path),
      link_to('CLIENTS', admin_clients_path)
    ]
    if resource.persisted?
      crumbs << link_to(resource.client.full_name.upcase, admin_client_path(resource.client))
    end
    crumbs
  end

  form title: 'Transfer Client' do |f|
    active_user = resource.user
    department = active_user&.department || Department.find(params['department_id'])
    department_users = department.users.active.order(full_name: :asc)
    options = options_from_collection_for_select(
      department_users,
      :id,
      :full_name,
      active_user.try(:id)
    )

    form_user = f.object.user || User.new(department: department)
    f.inputs 'Change user', for: form_user do |u|
      u.input :department_id, as: :hidden
      # rubocop:disable Rails/OutputSafety
      u.template.concat "<input type='hidden' id='reporting_relationship_client_id' name='reporting_relationship[client_id]' value='#{params['client_id']}'>".html_safe
      u.template.concat "<li><label class='label'>Current user</label><span>#{form_user.full_name || 'None'}</span></li>".html_safe
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
    def create
      rr_id = params['id']
      client_id = params['reporting_relationship']['client_id']
      target_user_id = params['reporting_relationship']['user']['id']
      transfer_note = params['transfer']['note']
      department_id = params['reporting_relationship']['user']['department_id']

      new_user = User.find_by(id: target_user_id, department_id: department_id)

      rr = ReportingRelationship.find_or_create_by(id: rr_id, user: new_user, client_id: client_id)

      client = rr.client
      department = Department.find(department_id)

      client.messages
            .scheduled
            .where(user: department.users)
            .update(user_id: new_user)

      ReportingRelationship.where(client: client, user: department.users).each do |relationship|
        relationship.update!(active: false)
      end

      new_user.reporting_relationships.find_or_create_by(client: client).update!(active: true)

      NotificationMailer.client_transfer_notification(
        current_user: new_user,
        previous_user: nil,
        client: client,
        transfer_note: transfer_note
      ).deliver_later

      analytics_track(
        label: :client_transfer,
        data: {
          admin_id: current_admin_user.id,
          clients_transferred_count: 1
        }
      )

      flash[:success] = "#{client.full_name} has been assigned to #{new_user.full_name} in #{department.name}"
      redirect_to(admin_client_path(client))
    end

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
        redirect_to(admin_client_path(client)) && return
      end

      client.messages
            .scheduled
            .where(user: department.users)
            .update(user_id: new_user)

      ReportingRelationship.where(client: client, user: department.users).each do |relationship|
        relationship.update!(active: false)
      end

      if new_user.blank?
        flash[:success] = "#{client.full_name} has been unassigned from #{previous_user.full_name} in #{department.name}"
        redirect_to(admin_client_path(client)) && return
      end

      new_user.reporting_relationships.find_or_create_by(client: client).update!(active: true)

      NotificationMailer.client_transfer_notification(
        current_user: new_user,
        previous_user: previous_user,
        client: client,
        transfer_note: transfer_note
      ).deliver_later

      analytics_track(
        label: :client_transfer,
        data: {
          admin_id: current_admin_user.id,
          clients_transferred_count: 1
        }
      )

      flash[:success] = "#{client.full_name} has been assigned to #{new_user.full_name} in #{department.name}"
      redirect_to(admin_client_path(client))
    end
  end

  def transfer_user
    # :TODO:
  end
end
