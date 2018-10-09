ActiveAdmin.register User do
  menu priority: 4

  permit_params :department_id, :full_name, :email, :phone_number, :password, :password_confirmation, :message_notification_emails, :treatment_group, :admin
  index do
    column :full_name
    column :email
    column :phone_number
    column :department
    column :active
    column :created_at

    actions defaults: true do |user|
      user.active ?
        link_to('Disable', disable_admin_user_path(user)) :
        link_to('Enable', enable_admin_user_path(user))
    end
  end

  actions :all, except: [:destroy]

  member_action :disable, method: :get do
    @page_title = "Disable #{resource.full_name}'s account"
    @clients_to_disable = resource.clients.active
  end

  member_action :enable, method: :get do
    resource.update!(active: true)

    redirect_to admin_users_path
  end

  member_action :disable_confirm, method: :get do
    resource.reporting_relationships.active.update(active: false)

    resource.update!(active: false)

    redirect_to admin_users_path
  end

  member_action :mark_messages_read, method: :get do
    resource.mark_messages_read
    flash[:success] = "Marked all messages for #{resource.full_name} read"
    redirect_to admin_user_path(resource)
  end

  filter :email
  filter :full_name
  filter :department
  filter :admin

  show do
    panel 'View Clients' do
      link_to 'Clients', admin_client_relationships_path(q: { user_id_eq: user.id })
    end

    panel 'User Details' do
      attributes_table_for user do
        row :department
        row :full_name
        row :email
        row :phone_number
        row :active
        row :admin
        row :message_notification_emails
        row :treatment_group
        row :current_sign_in_at
        row :current_sign_in_ip
        row :updated_at
        row :created_at
        row :reset_password_sent_at
      end
    end
  end

  form do |f|
    if f.object.errors.messages.keys.include? :reporting_relationships
      f.object.errors.add(:department, f.object.errors.messages[:reporting_relationships].first)
    end

    panel 'View Clients' do
      link_to 'Clients', admin_client_relationships_path(q: { user_id_eq: user.id })
    end

    f.inputs 'User Info' do
      f.input :full_name
      f.input :email
      f.input :phone_number, label: 'Desk phone number'
      f.input :message_notification_emails, as: :radio unless f.object.new_record?
      f.input :treatment_group
      f.input :admin, as: :radio

      if f.object.new_record?
        f.input :password
        f.input :password_confirmation
      end

      f.input :department, as: :select, collection: Department.all, include_blank: false
    end

    unless f.object.new_record?
      panel 'Unread messages' do
        message_count = user.messages.unread.count
        if message_count.positive?
          relationship_count = user.messages.unread.map(&:reporting_relationship_id).uniq.count
          link_to("Mark #{pluralize(message_count, 'message')} on #{pluralize(relationship_count, 'relationship')} read", mark_messages_read_admin_user_path(user))
        else
          'No unread messages'
        end
      end
    end

    unless f.object.new_record?
      panel 'User Status' do
        user.active ?
            link_to('Disable', disable_admin_user_path(user)) :
            link_to('Enable', enable_admin_user_path(user))
      end
    end

    f.actions
  end
end
