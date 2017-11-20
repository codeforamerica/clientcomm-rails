class ClientsController < ApplicationController
  include ClientStatusHelper
  before_action :authenticate_user!

  def index
    @clients = SortClients.clients_list(user: current_user)
    @clients_by_status = client_statuses(user: current_user) if FeatureFlag.enabled?('client_status')

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
    @client = Client.find_or_initialize_by(
      phone_number: client_params[:phone_number]
    )
    @client.first_name = client_params[:first_name]
    @client.last_name = client_params[:last_name]
    @client.notes = client_params[:notes]
    @client.client_status_id = client_params[:client_status_id]

    rr = ReportingRelationship.create(
      user: current_user, client: @client
    )
    unless rr.save
      if rr.errors.added? :client, :taken
        flash[:notice] = t('flash.notices.client.taken')
        redirect_to client_messages_path @client
        return
      end

      if rr.errors.added? :client, :existing_dept_relationship
        flash[:alert] = t('flash.errors.client.invalid')
        @client.errors.add(
          :phone_number,
          :existing_dept_relationship,
          user_full_name: rr.matching_record.user.full_name
        )
        render :new
        return
      end
    end

    if @client.save
      analytics_track(
        label: 'client_create_success',
        data: @client.reload.analytics_tracker_data
      )
      redirect_to client_messages_path(@client)
      return
    end

    flash[:alert] = t('flash.errors.client.invalid')
    render :new
  end

  def edit
    @client = current_user.clients.find(params[:id])

    analytics_track(
      label: 'client_edit_view',
      data: @client.analytics_tracker_data.merge(source: request.referer)
    )
  end

  def update
    @client = current_user.clients.find(params[:id])
    if @client.update_attributes(client_params)
      flash[:notice] = 'Client updated'

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
