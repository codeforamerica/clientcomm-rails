ActiveAdmin.register Client do
  menu priority: 4

  config.sort_order = 'last_name_asc'

  permit_params :user_id, :first_name, :last_name, :phone_number, :notes, :active, :client_status_id
  index do
    selectable_column
    column :full_name, sortable: :last_name
    Department.all.each do |dept|
      column "#{dept.name} User" do |client|
        dept_user = dept.users
                        .joins(:reporting_relationships)
                        .where(reporting_relationships: { active: true })
                        .find_by(reporting_relationships: { client: client })
        dept_user.try(:full_name)
      end
    end
    column :phone_number
    column :active
    column :notes
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
      f.input :client_status if FeatureFlag.enabled?('client_status')
      f.input :notes
      Department.all.each do |department|
        department_users = department.users.active.order(full_name: :asc)
        active_user_id = department.users
                                   .joins(:clients)
                                   .joins(:reporting_relationships)
                                   .where(clients: { id: resource.id })
                                   .find_by(reporting_relationships: { active: true })
                                   .try(:id)

        options = options_from_collection_for_select(
          department_users,
          :id,
          :full_name,
          active_user_id
        )

        f.input :users, {
          label: "User for #{department.name}",
          as: :select,
          collection: options,
          include_blank: true,
          input_html: { multiple: false, id: "user_in_dept_#{department.id}" }
        }
      end
    end

    f.actions
  end

  controller do
    def index
      params[:q][:phone_number_cont] = params[:q][:phone_number_cont].gsub(/\D/, '') if params[:q].try(:[], :phone_number_cont)

      super
    end

    def update
      user_ids = params[:client][:user_ids]

      Department.all.each do |dept|
        new_user = dept.users.find_by(id: user_ids)

        previous_user = resource.users
                                .joins(:reporting_relationships)
                                .where(reporting_relationships: { active: true })
                                .find_by(department: dept)

        next if new_user == previous_user

        resource.messages
                .scheduled
                .where(user: previous_user)
                .update(user_id: new_user)

        if previous_user.present?
          previous_user.reporting_relationships.find_by(client: resource).update!(active: false)
        end

        next if new_user.blank?
        new_user.reporting_relationships.find_or_create_by(client: resource).update!(active: true)

        NotificationMailer.client_transfer_notification(
          current_user: new_user,
          previous_user: previous_user,
          client: resource
        ).deliver_later

        analytics_track(
          label: :client_transfer,
          data: {
            admin_id: current_admin_user.id,
            clients_transferred_count: 1
          }
        )
      end

      super do |success, failure|
        success.html do
          render :show
        end
        failure.html do
          render :edit
        end
      end
    end
  end
end
