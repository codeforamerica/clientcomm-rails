ActiveAdmin.register Client do
  menu false

  config.sort_order = 'last_name_asc'

  permit_params :first_name, :last_name, :phone_number, :next_court_date_at, :id_number, :notes, :active, :client_status_id, user_ids: []

  show do
    panel 'Client Details' do
      attributes_table_for client do
        row :first_name
        row :last_name
        row :phone_number
        row :next_court_date_at
        row :id_number
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
          row :active, &:active
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

  actions :all, except: [:destroy]

  filter :reporting_relationships_user_id,
         as: :select,
         collection: proc { User.all.order(full_name: :asc) },
         label: 'User'
  filter :first_name_cont, label: 'Client first name'
  filter :last_name_cont, label: 'Client last name'
  filter :phone_number_cont, label: 'Phone Number'

  member_action :deactivate, method: :post do
    rr = resource.reporting_relationships.find(params[:reporting_relationship_id])
    rr.deactivate

    user = rr.user
    dept = user.department
    flash[:success] = "#{resource.full_name} has been deactivated for #{user.full_name} in #{dept.name}."
    redirect_to admin_client_path(resource)
  end

  member_action :reactivate, method: :post do
    rr = resource.reporting_relationships.find(params[:reporting_relationship_id])
    rr.update(active: true)

    user = rr.user
    dept = user.department
    flash[:success] = "#{resource.full_name} has been reactivated for #{user.full_name} in #{dept.name}."
    redirect_to admin_client_path(resource)
  end

  form do |f|
    f.inputs 'Client Info' do
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :next_court_date_at
      f.input :id_number

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

          f.input :users, label: "#{department.name} user:",
                          as: :select,
                          collection: options,
                          include_blank: true,
                          input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
        else # EDIT
          li do
            label "#{department.name} user:"
            if active_user.present?
              rr = resource.reporting_relationships.find_by(user: active_user)
              span active_user.full_name, disabled: true
              a 'Change', href: edit_admin_reporting_relationship_path(rr)
              a 'Deactivate', href: deactivate_admin_client_path(resource, reporting_relationship_id: rr.id), 'data-method': :post
            else
              last_active_user = department.users
                                           .joins(:clients)
                                           .joins(:reporting_relationships)
                                           .where(clients: { id: resource.id })
                                           .order('reporting_relationships.updated_at DESC')
                                           .first
              if last_active_user
                rr = resource.reporting_relationships.find_by(user: last_active_user)
                span last_active_user.full_name, disabled: true
                a 'Change', href: edit_admin_reporting_relationship_path(rr)
                a 'Reactivate', href: reactivate_admin_client_path(resource, reporting_relationship_id: rr.id), 'data-method': :post
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
    end

    f.actions
  end

  controller do
    def index
      redirect_to admin_client_relationships_path
    end

    def update
      super do |_format|
        if @client.phone_number_previously_changed?
          Message.create_client_edit_markers(
            user: current_admin_user,
            phone_number: @client.phone_number,
            reporting_relationships: @client.reporting_relationships.active
          )
        end
      end
    end
  end
end
