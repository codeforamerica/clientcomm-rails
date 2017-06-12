class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = sorted_clients

    respond_to do |format|
      format.html
      format.js
    end
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

  def sorted_clients
    # sort clients with unread messages to the top,
    # no matter when they were last contacted
    current_user.clients.all.sort{
      |c1, c2| [c2.unread_message_count, c2.contacted_at] <=> [c1.unread_message_count, c1.contacted_at]
    }
  end

end
