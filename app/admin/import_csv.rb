require 'csv'

class ImportCsv
  include ActiveModel::Model
  attr_accessor :file, :clients

  def initialize(attributes = {})
    super
    @clients ||= []
  end

  validate :clients_are_all_valid

  def save
    return false unless valid?
    @clients.each(&:save)
  end

  private

  def clients_are_all_valid
    errors.add(:file, 'Invalid Clients') unless @clients.all?(&:valid?)
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

      csv = CSV.parse(@import_csv.file, headers: true)
      csv.each do |row|
        entry = row.to_hash
        client = Client.new(
          phone_number: entry['phone_number'],
          last_name: entry['last_name'],
          first_name: entry['first_name'],
          user: User.find_by_email(entry['user'])
        )

        @import_csv.clients << client
      end

      if @import_csv.save
        redirect_to :admin_clients, notice: 'Clients Created Succesfully'
      else
        render :new
      end
    end
  end
end
