class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = current_user.clients.order('updated_at DESC')
  end

  def new
    @client = Client.new
  end

  def create
    # normalize the client's phone number
    params = client_params
    params[:phone_number] = PhoneNumberParser.normalize(params[:phone_number])
    # create the client
    current_user.clients.create(params)

    redirect_to clients_path
  end

  private

  def client_params
    params.fetch(:client, {})
      .permit(:first_name, :last_name, :birth_date, :phone_number, :active)
  end
end
