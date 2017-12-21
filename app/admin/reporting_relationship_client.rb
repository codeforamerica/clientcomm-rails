ActiveAdmin.register ReportingRelationship, as: 'Client Relationships' do
  menu priority: 4

  permit_params :first_name, :last_name, :phone_number, :notes, :active, :client_status_id, user_ids: []

  scope :all, default: true
  Department.all.each do |department|
    scope department.name
  end

  index do
    selectable_column
    column :full_name, sortable: 'clients.last_name' do |rr|
      rr.client&.full_name
    end

    column 'Department' do |rr|
      rr.user&.department
    end

    column :user, sortable: 'users.full_name'
    column :active
    column :phone_number do |rr|
      rr.client.phone_number
    end
    actions defaults: false do |rr|
      a 'View', href: admin_client_path(rr.client)
      a 'Edit', href: edit_admin_client_path(rr.client)
    end
  end

  action_item :bulk_import, only: :index { link_to 'Bulk Import', new_admin_import_csv_path }

  actions :all, :except => [:destroy]

  filter :user_id,
         as: :select,
         collection: proc { User.all.order(full_name: :asc) },
         label: 'User'
  filter :client_first_name_cont, label: 'Client first name'
  filter :client_last_name_cont, label: 'Client last name'
  filter :client_phone_number_cont, label: 'Phone Number'
  filter :active

  controller do
    def scoped_collection
      ReportingRelationship.includes(:client, :user)
    end

    def index
      params[:q][:phone_number_cont] = params[:q][:phone_number_cont].gsub(/\D/, '') if params[:q].try(:[], :phone_number_cont)

      super
    end
  end
end
