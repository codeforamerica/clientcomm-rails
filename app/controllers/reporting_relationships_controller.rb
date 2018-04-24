class ReportingRelationshipsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def show
    @rr = current_user.reporting_relationships.find params[:id]

    @client = @rr.client

    unless @client.active(user: current_user)
      redirect_to(clients_path, notice: t('flash.notices.client.unauthorized')) && return
    end

    reporting_relationship = @client.reporting_relationship(user: current_user)

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data.merge(reporting_relationship.analytics_tracker_data)
    )

    @templates = current_user.templates

    # the list of past messages
    @messages = past_messages
    @messages.update_all(read: true)
    @client.reporting_relationship(user: current_user).update(has_unread_messages: false)

    @message = Message.new(send_at: default_send_at)
    @sendfocus = true

    @messages_scheduled = @rr.messages.scheduled
  rescue ActiveRecord::RecordNotFound
    redirect_to(clients_path, notice: t('flash.notices.client.unauthorized'))
  end

  def create
    @reporting_relationship = ReportingRelationship
                              .find_by(user: current_user.id, client_id: reporting_relationship_params['client_id'])
    @client = Client.find(reporting_relationship_params['client_id'])
    @transfer_reporting_relationship = ReportingRelationship.find_or_initialize_by(reporting_relationship_params)

    had_unread_messages = @reporting_relationship.has_unread_messages

    begin
      @reporting_relationship.transfer_to(@transfer_reporting_relationship)
    rescue ActiveRecord::RecordInvalid
      @transfer_users = current_user.department.eligible_users.active
                                    .where.not(id: current_user.id)
                                    .order(:full_name).pluck(:full_name, :id)
      render 'clients/edit'
      return
    end

    transferred_by = 'user'
    user = User.find(reporting_relationship_params['user_id'])

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: current_user,
      client: @client,
      transfer_note: transfer_note,
      transferred_by: transferred_by
    ).deliver_later

    analytics_track(
      label: :client_transfer,
      data: {
        admin_id: nil,
        clients_transferred_count: 1,
        transferred_by: transferred_by,
        has_transfer_note: transfer_note.present?,
        unread_messages: had_unread_messages
      }
    )

    redirect_to(
      clients_path,
      notice: t(
        'flash.notices.client.transferred',
        client_full_name: @client.full_name,
        user_full_name: user.full_name
      )
    )
  end

  def update
    @rr = current_user.reporting_relationships.find params[:id]

    @rr.update!(reporting_relationship_update_params)
  end

  private

  def transfer_note
    params['transfer_note']
  end

  def reporting_relationship_update_params
    params.require(:reporting_relationship).permit(:category)
  end

  def reporting_relationship_params
    params.require(:reporting_relationship).permit(:user_id, :client_id)
  end

  def default_send_at
    Time.current.beginning_of_day + 9.hours
  end

  def past_messages
    @rr.messages
       .where('send_at < ?', Time.now)
       .order('send_at ASC')
  end
end
