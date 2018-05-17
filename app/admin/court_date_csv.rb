ActiveAdmin.register CourtDateCSV do
  permit_params :file

  form do |f|
    f.inputs 'Upload CSV' do
      f.input :file, as: :file
    end

    f.actions do
      f.action :submit, label: 'Upload CSV'
    end
  end

  controller do
    def create
      @court_date_csv = CourtDateCSV.create(file: permitted_params[:court_date_csv][:file])
      CreateCourtRemindersJob.perform_later(@court_date_csv, current_admin_user)
      redirect_to :admin_court_date_csvs, notice: 'Uploading in process. You will receive an email shortly.'
    end
  end
end