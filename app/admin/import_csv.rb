require 'csv'

class ImportCsv
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  attr_accessor :file

  before_validation :populate_clients
  validate :relationships_are_all_valid

  def initialize(attributes = {})
    super
    @clients = []
    @relationships = []
  end

  def save
    return false unless valid?
    @clients.each(&:save)
    @relationships.each(&:save)
  end

  private

  def populate_clients
    CSV.parse(@file, headers: true).each do |row|
      entry = row.to_hash
      user = User.find_by(email: entry['user'])

      client = Client.find_or_initialize_by(
        phone_number: entry['phone_number']
      ) do |new_client|
        new_client.last_name = entry['last_name']
        new_client.first_name = entry['first_name']
        new_client.users = [user]
      end

      @relationships << ReportingRelationship.new(client: client, user: user) if client.persisted?

      @clients << client
    end
  end

  def relationships_are_all_valid
    @relationships.each do |rr|
      unless rr.valid?
        if rr.errors.added? :client, :taken
          @relationships.delete rr
        else
          errors.add(:file, 'Invalid Clients') unless @relationships.all?(&:valid?)
        end
      end
    end
  end
end

ActiveAdmin.register ImportCsv do
  menu false

  permit_params :file

  form do |f|
    f.inputs 'Upload CSV' do
      f.input :file, as: :file
    end

    f.actions do
      f.action :submit, label: 'Upload CSV'
      f.action :cancel, url: :admin_clients, label: 'Cancel'
    end
  end

  controller do
    def index
      redirect_to :new_admin_import_csv
    end

    def create
      @import_csv = ImportCsv.new(file: permitted_params[:import_csv][:file].read)

      if @import_csv.save
        redirect_to :admin_clients, notice: 'Clients Created Succesfully'
      else
        render :new
      end
    end
  end
end
