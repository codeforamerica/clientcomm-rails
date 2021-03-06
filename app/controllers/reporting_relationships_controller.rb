class ReportingRelationshipsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def show
    @rr = current_user.reporting_relationships.find params[:id]

    @client = @rr.client

    unless @rr.active
      redirect_to(clients_path, notice: t('flash.notices.client.unauthorized')) && return
    end

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data.merge(@rr.analytics_tracker_data)
    )

    # the list of past messages
    @messages = past_messages

    @message = Message.new(send_at: default_send_at)
    @sendfocus = true

    @messages_scheduled = @rr.messages.messages.scheduled
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
      @transfer_users = ListMaker.transfer_users user: current_user
      @merge_reporting_relationship = MergeReportingRelationship.new
      @merge_clients = ListMaker.merge_clients user: current_user, client: @client

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
    previous_category = @rr.category
    @rr.update!(reporting_relationship_update_params)

    if previous_category == ReportingRelationship::CATEGORIES.keys.first
      analytics_track(
        label: :symbol_add,
        data: {
          'category': @rr.category
        }
      )
    else
      analytics_track(
        label: :symbol_update,
        data: {
          'previous_category': previous_category,
          'new_category': @rr.category
        }
      )
    end
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
       .where('send_at < ?', Time.zone.now)
       .order('send_at ASC')
  end
end
