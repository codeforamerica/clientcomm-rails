ActiveAdmin.register CourtDateCSV do
  permit_params :file
  actions :all, except: %i[destroy edit]
  form do |f|
    f.inputs 'Upload CSV' do
      f.input :file, as: :file
    end

    f.actions do
      f.action :submit, label: 'Upload CSV'
    end
  end

  show do
    panel 'Court Reminder CSV Details' do
      attributes_table_for court_date_csv do
        row 'File file name' do
          link_to court_date_csv.file_file_name, download_admin_court_date_csv_path(court_date_csv)
        end
        row :file_content_type
        row :file_file_size
        row :file_updated_at
        row :user
      end
    end
  end

  member_action :download, method: :get do
    send_data(Paperclip.io_adapters.for(resource.file).read, type: 'text/csv', filename: resource.file_file_name)
  end

  controller do
    def create
      @court_date_csv = CourtDateCSV.create(file: permitted_params[:court_date_csv][:file], user: current_user)
      CreateCourtRemindersJob.perform_later(@court_date_csv, current_user)
      analytics_track(
        label: 'court_reminder_upload',
        data: { admin_id: current_user.id }
      )
      redirect_to :admin_court_date_csvs, notice: 'Uploading in process. You will receive an email shortly.'
    end
  end
end
