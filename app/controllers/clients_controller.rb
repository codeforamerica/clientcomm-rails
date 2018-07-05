class ClientsController < ApplicationController
  before_action :authenticate_user!

  def index
    @change_image = ChangeImage.order('RANDOM()').all.first
    @reporting_relationships = current_user.active_reporting_relationships
    @relationships_by_status = current_user.relationships_with_statuses_due_for_follow_up
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

      rr = current_user.reporting_relationships.find_by(client: @client)
      redirect_to reporting_relationship_path(rr)
      return
    end

    if @client.errors.added?(:phone_number, :taken)
      @existing_client = Client.find_by(phone_number: @client.phone_number)
      conflicting_user = @existing_client.users.active_rr.where.not(id: current_user.id)
                                         .find_by(department: current_user.department)
      if conflicting_user
        @client.errors.delete(:phone_number)
        @client.errors.add(
          :phone_number,
          t(
            'activerecord.errors.models.reporting_relationship.attributes.client.existing_dept_relationship',
            user_full_name: conflicting_user.full_name
          )
        )
      elsif current_user.clients.include? @existing_client
        existing_relationship = current_user.reporting_relationships.find_by(client: @existing_client)
        flash[:notice] = t('flash.notices.client.taken') if existing_relationship.active?
        existing_relationship.update(active: true)
        redirect_to reporting_relationship_path(existing_relationship)
        return
      else
        rr_params = client_params[:reporting_relationships_attributes]['0']
        @reporting_relationship = @existing_client.reporting_relationships.new(rr_params)
        if params[:user_confirmed] == 'true'
          @reporting_relationship.save!
          redirect_to reporting_relationship_path(@reporting_relationship)
          return
        end
        render :confirm
        return
      end
    end
    track_errors('create')
    flash.now[:alert] = t('flash.errors.client.invalid')
    render :new
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def edit
    @client = current_user.clients.find(params[:id])
    @reporting_relationship = @client.reporting_relationships.find_by(user: current_user)
    @transfer_reporting_relationship = ReportingRelationship.new
    @transfer_users = current_user.department.eligible_users.active
                                  .where.not(id: current_user.id)
                                  .order(:full_name).pluck(:full_name, :id)
    analytics_track(
      label: 'client_edit_view',
      data: @client.analytics_tracker_data.merge(source: request.referer)
    )
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def update
    @client = current_user.clients.find(params[:id])
    @reporting_relationship = @client.reporting_relationship(user: current_user)
    @transfer_reporting_relationship = ReportingRelationship.new
    @transfer_users = current_user.department.eligible_users.where.not(id: current_user.id).pluck(:full_name, :id)

    @client.assign_attributes(client_params)
    @client.next_court_date_set_by_user = client_params[:next_court_date_at].present? if @client.next_court_date_at_changed? || client_params[:next_court_date_at].blank?

    if @client.save
      if @reporting_relationship.reload.active
        notify_users_of_changes
        analytics_track(
          label: 'client_edit_success',
          data: @client.analytics_tracker_data
                  .merge(@reporting_relationship.analytics_tracker_data)
        )
        redirect_to reporting_relationship_path(@reporting_relationship)
      else
        @reporting_relationship.deactivate
        analytics_track(
          label: 'client_deactivate_success',
          data: {
            client_id: @client.id,
            client_duration: (Date.current - @client.relationship_started(user: current_user).to_date).to_i
          }
        )

        redirect_to clients_path, notice: t('flash.notices.client.deactivated', client_full_name: @client.full_name)
      end
      return
    elsif @client.errors.added?(:phone_number, :taken)
      @existing_client = Client.find_by(phone_number: @client.phone_number)
      error_text = phone_number_conflict_error_text

      if error_text
        @client.errors.delete(:phone_number)
        @client.errors.add(:phone_number, error_text)
      end
    end

    track_errors('edit')
    flash.now[:alert] = t('flash.errors.client.invalid')
    render :edit
  end
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def track_errors(method)
    error_types = []
    @client.errors.details.each do |column, errors|
      errors.each do |item|
        error_types << "#{column}_#{item[:error]}"
      end
    end

    analytics_track(
      label: "client_#{method}_error",
      data: @client.analytics_tracker_data.merge(error_types: error_types)
    )
  end

  def notify_users_of_changes
    if @client.phone_number_previously_changed?
      Message.create_client_edit_markers(
        user: current_user,
        phone_number: @client.phone_number,
        reporting_relationships: @client.reporting_relationships.active
      )
    end

    other_active_relationships = @client.reporting_relationships
                                        .active.where.not(user: current_user)
    other_active_relationships.each do |rr|
      NotificationMailer.client_edit_notification(
        notified_user: rr.user,
        editing_user: current_user,
        client: @client,
        previous_changes: @client.previous_changes.except(:updated_at, :next_court_date_at)
      ).deliver_later
    end
  end

  def phone_number_conflict_error_text
    active_current_rr = ReportingRelationship.find_by(user: current_user, client: @existing_client, active: true)
    conflicting_user = @existing_client.users.where.not(id: current_user.id).find_by(department: current_user.department)
    error_text = nil

    if active_current_rr
      error_text = t(
        'activerecord.errors.models.reporting_relationship.attributes.client.existing_user_relationship',
        client_full_name: "#{@existing_client.first_name} #{@existing_client.last_name}",
        href: reporting_relationship_url(active_current_rr)
      )
    elsif conflicting_user
      error_text = t(
        'activerecord.errors.models.reporting_relationship.attributes.client.existing_dept_relationship',
        user_full_name: conflicting_user.full_name
      )
    end

    error_text
  end

  def client_params
    params.fetch(:client)
          .permit(:first_name,
                  :last_name,
                  :client_status_id,
                  :id_number,
                  :phone_number,
                  :next_court_date_at,
                  :notes,
                  reporting_relationships_attributes: %i[
                    id notes client_status_id active
                  ],
                  surveys_attributes: [
                    survey_response_ids: []
                  ]).tap do |p|
      p[:reporting_relationships_attributes]['0'][:user_id] = current_user.id
      p[:surveys_attributes]['0'][:user_id] = current_user.id if p.dig(:surveys_attributes, '0')
      p[:next_court_date_at] = Date.strptime(p[:next_court_date_at], '%m/%d/%Y').strftime('%d/%m/%Y') if p[:next_court_date_at].present?
    end
  end
end
