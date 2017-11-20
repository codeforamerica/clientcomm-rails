class Clients::ArchivesController < ApplicationController
  before_action :authenticate_user!

  def create
    @client = client
    @client.update_attributes(client_params)

    typeform_link = ENV.fetch('TYPEFORM_LINK', nil)

    analytics_track(
      label: 'client_archive_success',
      data: {
        client_id: @client.id,
        client_duration: (Date.current - @client.created_at.to_date).to_i
      }
    )

    if typeform_link.present?
      IntercomRails.config.hide_default_launcher = true
      render :show, locals: { typeform_link: typeform_link }
    else
      redirect_to clients_path, notice: "#{client.full_name} has been successfully deleted"
    end
  end

  private

  def client
    current_user.clients.find params[:client_id]
  end

  def client_params
    params.require(:client)
          .permit(reporting_relationships_attributes: %i[id active])
  end
end
