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
    @reporting_relationship = @client.reporting_relationships.build(user: current_user)

    analytics_track(
      label: 'client_create_view'
    )
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def create
    @client = Client.new(client_params)

    if @client.save
      analytics_track(
        label: 'client_create_success',
        data: @client.reload.analytics_tracker_data
      )

      redirect_to client_messages_path(@client)
      return
    end

    if @client.errors.added?(:phone_number, :taken)
      @existing_client = Client.find_by(phone_number: @client.phone_number)
      conflicting_user = @existing_client.users
                                         .where.not(id: current_user.id)
                                         .find_by(department: current_user.department)
      if conflicting_user
        @client.errors.add(
          :phone_number,
          :existing_dept_relationship,
          user_full_name: conflicting_user.full_name
        )
      elsif current_user.clients.include? @existing_client
        existing_relationship = current_user.reporting_relationships.find_by(client: @existing_client)
        flash[:notice] = t('flash.notices.client.taken') if existing_relationship.active?
        existing_relationship.update(active: true)
        redirect_to client_messages_path(@existing_client)
        return
      else
        rr_params = client_params[:reporting_relationships_attributes]['0']
        @reporting_relationship = @existing_client.reporting_relationships.new(rr_params)
        if params[:user_confirmed] == 'true'
          @reporting_relationship.save!
          redirect_to client_messages_path(@existing_client)
          return
        end
        render :confirm
        return
      end
    end

    flash[:alert] = t('flash.errors.client.invalid')
    render :new
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def edit
    @client = current_user.clients.find(params[:id])
    @reporting_relationship = @client.reporting_relationships.find_by(user: current_user)

    analytics_track(
      label: 'client_edit_view',
      data: @client.analytics_tracker_data.merge(source: request.referer)
    )
  end

  def update
    @client = current_user.clients.find(params[:id])
    if @client.update_attributes(client_params)
      flash[:notice] = 'Client updated'

      reporting_relationship = @client.reporting_relationships
                                      .find_by(user: current_user)

      other_active_relationships = @client.reporting_relationships
                                          .active.where.not(user: current_user)

      if other_active_relationships.any?
        other_active_relationships.each do |rr|
          NotificationMailer.client_edit_notification(
            notified_user: rr.user,
            editing_user: current_user,
            client: @client,
            previous_changes: @client.previous_changes.except(:updated_at)
          ).deliver_later
        end
      end

      analytics_track(
        label: 'client_edit_success',
        data: @client.analytics_tracker_data
                .merge(reporting_relationship.analytics_tracker_data)
      )

      redirect_to client_messages_path(@client)
    else
      flash[:alert] = t('flash.errors.client.invalid')
      render :edit
    end
  end

  private

  def client_params
    params.fetch(:client)
          .permit(:first_name,
                  :last_name,
                  :client_status_id,
                  :phone_number,
                  :notes,
                  reporting_relationships_attributes: %i[
                    id notes client_status_id active
                  ],
                  surveys_attributes: [
                    survey_response_ids: []
                  ]).tap do |p|
      p[:reporting_relationships_attributes]['0'][:user_id] = current_user.id
      p[:surveys_attributes]['0'][:user_id] = current_user.id
    end
  end
end
