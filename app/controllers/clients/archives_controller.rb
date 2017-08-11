class Clients::ArchivesController < ApplicationController
  before_action :authenticate_user!

  def create
    # change the archive status of the client
    @client = client
    @client.update!(active: client_params[:active])

    typeform_link = ENV.fetch('TYPEFORM_LINK', nil)

    if typeform_link
      render :show, locals: { typeform_link: typeform_link }
    else
      redirect_to clients_path
    end
  end

  private

  def client
    current_user.clients.find params[:client_id]
  end

  def client_params
    params.require(:client)
      .permit(:active)
  end
end

