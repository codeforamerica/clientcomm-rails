ActiveAdmin.register ReportingRelationship do
  menu false

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

    unread_warning = resource.messages.unread.any? ? I18n.t('views.admin.reporting_relationships.edit.unread_transfer') : ''
    transfer_label = resource.messages.unread.any? ? 'Transfer Client and Mark Messages As Read' : 'Transfer Client'

    form_user = f.object.user || User.new(department: department)
    f.inputs 'Change user', for: form_user do |u|
      u.input :department_id, as: :hidden
      # rubocop:disable Rails/OutputSafety
      u.template.concat "<input type='hidden' id='reporting_relationship_client_id' name='reporting_relationship[client_id]' value='#{params['client_id']}'>".html_safe
      u.template.concat "<input type='hidden' id='reporting_relationship_force_transfer' name='reporting_relationship[force_transfer]' value='true'>".html_safe if resource.messages.unread.any?
      u.template.concat "<li><label class='label'>Current user</label><span>#{form_user.full_name || 'None'}</span></li>".html_safe
      u.input :id, label: 'Transfer to:',
                   as: :select,
                   collection: options,
                   include_blank: true,
                   hint: unread_warning,
                   input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
      u.template.concat "<li><label class='label' for='transfer_note'>Include a message for the new user</label><textarea id='transfer_note' name='transfer[note]'></textarea></li>".html_safe
      # rubocop:enable Rails/OutputSafety
    end
    f.actions do
      f.action :submit, as: :button, label: transfer_label
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
      old_users = department.users

      transfer_messages(client: client, old_users: old_users, new_user: new_user)

      deactivate_old_relationships(client: client, users: old_users)

      transfer_client_and_mail_and_track(
        client: client, previous_user: nil, new_user: new_user, transfer_note: transfer_note, client_status: nil
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

      if rr.messages.unread.any? && !params['reporting_relationship']['force_transfer']
        redirect_to(edit_admin_reporting_relationship_path(rr))
        return
      end

      rr.messages.unread.update(read: true)

      redirect_to(admin_client_path(rr.client)) && return if new_user == previous_user

      client = rr.client
      department = Department.find(department_id)
      old_users = department.users

      had_unread_messages = rr.has_unread_messages

      deactivate_old_relationships(client: client, users: old_users)

      if new_user.blank?
        flash[:success] = "#{client.full_name} has been deactivated for #{previous_user.full_name} in #{department.name}."
        redirect_to(admin_client_path(client)) && return
      end

      transfer_client_and_mail_and_track(
        client: client,
        previous_user: previous_user,
        new_user: new_user,
        transfer_note: transfer_note,
        client_status: rr.client_status,
        unread_messages: had_unread_messages
      )

      transfer_messages(client: client, old_users: old_users, new_user: new_user)

      new_rr = ReportingRelationship.find_by(client: client, user: new_user)
      Message.create_transfer_markers(sending_rr: rr, receiving_rr: new_rr)

      flash[:success] = "#{client.full_name} has been assigned to #{new_user.full_name} in #{department.name}"
      redirect_to(admin_client_path(client))
    end

    private

    def transfer_messages(client:, old_users:, new_user:)
      original_rrs = ReportingRelationship.where(client: client, user: old_users)
      original_messages = Message.where(reporting_relationship: original_rrs).scheduled

      new_rr = ReportingRelationship.find_by(client: client, user: new_user)
      original_messages.update(reporting_relationship: new_rr)

      # rubocop:disable Style/GuardClause
      if new_user.present?
        unclaimed_rr = ReportingRelationship.find_by(client: client, user: new_user.department.unclaimed_user)
        unclaimed_messages = unclaimed_rr.messages if unclaimed_rr
        unclaimed_messages.update(reporting_relationship: new_rr) if unclaimed_messages.present?
      end
      # rubocop:enable Style/GuardClause
    end

    def deactivate_old_relationships(client:, users:)
      ReportingRelationship.where(client: client, user: users).each do |relationship|
        relationship.update!(active: false, has_unread_messages: false)
      end
    end

    def transfer_client_and_mail_and_track(client:, previous_user:, new_user:, transfer_note:, client_status:, unread_messages:)
      new_user.reporting_relationships.find_or_create_by(client: client).update!(active: true, client_status: client_status)
      NotificationMailer.client_transfer_notification(
        current_user: new_user,
        previous_user: previous_user,
        client: client,
        transfer_note: transfer_note,
        transferred_by: 'admin'
      ).deliver_later

      analytics_track(
        label: :client_transfer,
        data: {
          admin_id: current_admin_user.id,
          clients_transferred_count: 1,
          transferred_by: 'admin',
          has_transfer_note: transfer_note.present?,
          unread_messages: unread_messages
        }
      )
    end
  end
end
