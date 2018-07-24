ActiveAdmin.register ChangeImage do
  menu priority: 2, label: 'Highlight Box', parent: 'Manage'

  permit_params :file
  actions :all, except: %i[edit]
  form do |f|
    f.inputs 'Upload image' do
      f.input :file, as: :file
    end

    f.actions do
      f.action :submit, label: 'Upload image'
    end
  end

  show do
    panel 'Change Image Details' do
      attributes_table_for change_image do
        row 'File file name' do
          link_to change_image.file_file_name, download_admin_change_image_path(change_image)
        end
        row :file_content_type
        row :file_file_size
        row :file_updated_at
        row :admin_user
      end
    end
  end

  member_action :download, method: :get do
    send_data(Paperclip.io_adapters.for(resource.file).read, type: resource.file_content_type, filename: resource.file_file_name)
  end

  controller do
    def create
      @change_image = ChangeImage.create(file: permitted_params[:change_image][:file], admin_user: current_admin_user)
      if @change_image.valid?
        redirect_to :admin_change_images, notice: 'Image uploaded.'
      else
        redirect_to :admin_change_images, alert: 'Image could not be uploaded!'
      end
    end
  end
end
