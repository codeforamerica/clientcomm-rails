class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = sorted_clients

    analytics_track(
      label: 'clients_view',
      data: current_user.analytics_tracker_data
    )

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @client = Client.new

    analytics_track(
      label: 'client_create_view'
    )
  end

  def create
    client = current_user.clients.create(client_params)

    analytics_track(
      label: 'client_create_success',
      data: client.analytics_tracker_data
    )
    redirect_to clients_path
  end

  def edit
    @client = current_user.clients.find(params[:id])
  end

  def update
    @client = current_user.clients.find(params[:id])
    if @client.update_attributes(client_params)
      flash[:success] = "Client Updated"
      redirect_to clients_path
    else
      render 'edit'
    end
  end

  private

  def client_params
    params.fetch(:client, {})
      .permit(:first_name, :last_name, :birth_date, :phone_number, :active)
  end

  def sorted_clients
    # sort clients with unread messages to the top,
    # no matter when they were last contacted
    current_user.clients.all.sort_by { |c| [c.unread_messages_sort, c.contacted_at] }.reverse
  end

end
