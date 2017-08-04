class Clients::ArchivesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    # change the archive status of the client
    client.update!(active: client_params[:active])

    redirect_to clients_path
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


