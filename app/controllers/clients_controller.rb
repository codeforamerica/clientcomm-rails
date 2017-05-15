class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = Client.order('updated_at DESC').all
  end

  def new
    @client = Client.new
  end

  def create
    Client.create(client_params)

    redirect_to clients_path
  end

  private

  def client_params
    params.fetch(:client, {})
      .permit(:first_name, :last_name, :birth_date, :phone_number, :active)
  end
end
