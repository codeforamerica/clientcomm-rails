class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @clients = SortClients.run(user: current_user)

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
    @client = Client.new(
      user: current_user,
      first_name: client_params[:first_name],
      last_name: client_params[:last_name],
      phone_number: client_params[:phone_number],
      notes: client_params[:notes]
    )

    if @client.save
      analytics_track(
          label: 'client_create_success',
          data: @client.reload.analytics_tracker_data
      )
      redirect_to client_messages_path(@client)
    else
      render :new
    end
  end

  def edit
    @client = current_user.clients.find(params[:id])

    analytics_track(
      label: 'client_edit_view',
      data: @client.analytics_tracker_data.merge(source: request.referrer)
    )
  end

  def update
    @client = current_user.clients.find(params[:id])
    if @client.update_attributes(client_params)
      flash[:notice] = "Client updated"

      analytics_track(
        label: 'client_edit_success',
        data: @client.analytics_tracker_data
      )

    redirect_to client_messages_path(@client)
    else
      render 'edit'
    end
  end

  private

  def client_params
    params.fetch(:client)
      .permit(:first_name, :last_name, :phone_number, :notes)
  end
end
