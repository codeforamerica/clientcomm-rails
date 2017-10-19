class ClientsController < ApplicationController
  include ClientStatusHelper
  before_action :authenticate_user!

  def index
    @clients = SortClients.run(user: current_user)
    @clients_by_status = client_statuses() if FeatureFlag.enabled?('client_status')

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
      notes: client_params[:notes],
      client_status_id: client_params[:client_status_id]
    )

    if @client.save
      analytics_track(
        label: 'client_create_success',
        data: @client.reload.analytics_tracker_data
      )
      redirect_to client_messages_path(@client)
      return
    end

    if @client.errors.added? :phone_number, :taken
      client = current_user.clients.find_by_phone_number(@client.phone_number)
      flash[:notice] = 'You already have a client with this number.'
      redirect_to client_messages_path(client)
      return
    end

    if @client.errors.added? :phone_number, :inactive_taken
      client = current_user.clients.find_by_phone_number(@client.phone_number)
      client.update!(active: true)
      flash[:notice] = "This client has been restored. If you didn't mean to do this, please contact us."
      redirect_to client_messages_path(client)
      return
    end

    flash[:alert] = t('flash.errors.client.invalid')
    render :new
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
      flash[:alert] = t('flash.errors.client.invalid')
      render 'edit'
    end
  end

  private

  def client_params
    params.fetch(:client)
      .permit(:first_name, :last_name, :client_status_id, :phone_number, :notes)
  end
end
