class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = sorted_clients

    analytics_track(
      label: 'client_list_view',
      data: current_user.analytics_tracker_data
    )

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
    current_user.clients.all.sort_by { |c| [c.unread_messages_sort, c.contacted_at] }.reverse
  end

end
