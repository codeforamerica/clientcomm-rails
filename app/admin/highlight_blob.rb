ActiveAdmin.register HighlightBlob do
  menu priority: 2, label: 'Highlight Box', parent: 'Manage'
  permit_params :text

  actions :all

  show title: 'Highlight Box' do
    panel 'Highlight Contents' do
      attributes_table_for highlight_blob do
        row(:text) { CGI.escapeHTML(highlight_blob.text) }
      end
    end
  end

  form do |f|
    f.inputs 'Text' do
      f.input :text
    end

    f.actions
  end

  controller do
    def index
      if HighlightBlob.first.present?
        redirect_to admin_highlight_blob_path(HighlightBlob.first)
      else
        redirect_to new_admin_highlight_blob_path
      end
    end

    def edit
      @page_title = 'Edit Highlight Box'
      super
    end

    def new
      @page_title = 'Create Highlight Box'
      super
    end
  end
end
