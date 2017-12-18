ActiveAdmin.register Client do
  menu priority: 4

  config.sort_order = 'last_name_asc'

  permit_params :first_name, :last_name, :phone_number, :notes, :active, :client_status_id, user_ids: []

  index do
    selectable_column
    column :full_name, sortable: :last_name

    column 'Departments' do |client|
      dep_users = {}
      active_users = client.users
                           .joins(:reporting_relationships)
                           .where(reporting_relationships: { active: true })

      active_users.each do |u|
        dep_users[u.department.name] = u.full_name
      end

      dep_users.sort.to_h.keys.join(', ')
    end

    column 'Users' do |client|
      dep_users = {}
      active_users = client.users
                           .joins(:reporting_relationships)
                           .where(reporting_relationships: { active: true })

      active_users.each do |u|
        dep_users[u.department.name] = u.full_name
      end

      dep_users.sort.to_h.values.join(', ')
    end

    column :phone_number
    actions
  end

  show do
    panel 'Client Details' do
      attributes_table_for client do
        row :first_name
        row :last_name
        row :phone_number
      end
    end

    Department.all.includes(:users).each do |dept|
      dept_users = dept.users
                       .joins(:reporting_relationships)
                       .where(reporting_relationships: { client: client })
                       .order('reporting_relationships.updated_at') # TODO: test ordering and make sure it's the right order

      user = dept_users.find { |u| client.reporting_relationship(user: u).active? } || dept_users.first

      next unless user
      panel "#{user.department.name}: #{user.full_name}" do
        attributes_table_for client.reporting_relationship(user: user) do
          row :active
          row :notes
          row(:created_at) { |rr| rr.created_at&.strftime('%B %d, %Y %l:%M %Z') }
          row(:last_contacted_at) { |rr| rr.last_contacted_at&.strftime('%B %d, %Y %l:%M %Z') }
          row :has_unread_messages
          row :has_message_error
        end
      end
    end
  end

  action_item :bulk_import, only: :index { link_to 'Bulk Import', new_admin_import_csv_path }

  actions :all, :except => [:destroy]

  filter :reporting_relationships_user_id,
         as: :select,
         collection: proc { User.all.order(full_name: :asc) },
         label: 'User'
  filter :first_name_cont, label: 'Client first name'
  filter :last_name_cont, label: 'Client last name'
  filter :phone_number_cont, label: 'Phone Number'

  form do |f|
    f.inputs 'Client Info' do
      f.input :first_name
      f.input :last_name
      f.input :phone_number

      Department.all.each do |department|
        department_users = department.users.active.order(full_name: :asc)
        active_user = department.users
                                .joins(:clients)
                                .joins(:reporting_relationships)
                                .where(clients: { id: resource.id })
                                .find_by(reporting_relationships: { active: true })

        if f.object.new_record? # NEW
          options = options_from_collection_for_select(
            department_users,
            :id,
            :full_name,
            active_user.try(:id)
          )

          f.input :users, {
            label: "#{department.name} user:",
            as: :select,
            collection: options,
            include_blank: true,
            input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
          }
        else # EDIT
          li do
            label "#{department.name} user:"
            if active_user.present?
              rr = resource.reporting_relationships.find_by(user: active_user)
              span active_user.full_name, disabled: true
              a 'Change', href: edit_admin_reporting_relationship_path(rr)
            else
              a 'Assign user',
                href: new_admin_reporting_relationship_path(
                  department_id: department.id, client_id: resource.id
                )
            end
          end
        end
      end
    end

    f.actions
  end

  controller do
    def index
      params[:q][:phone_number_cont] = params[:q][:phone_number_cont].gsub(/\D/, '') if params[:q].try(:[], :phone_number_cont)

      super
    end
  end
end
