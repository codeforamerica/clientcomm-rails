class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = current_user.clients.all.sort_by(&:contacted_at).reverse
  end

  def new
    @client = Client.new
  end

  def create
    current_user.clients.create(client_params)

    redirect_to clients_path
  end

  private

  def client_params
    params.fetch(:client, {})
      .permit(:first_name, :last_name, :birth_date, :phone_number, :active)
  end
end
