class ScheduledMessagesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def index
    @client = current_user.clients.find params[:client_id]
    @templates = current_user.templates

    analytics_track(
      label: 'client_scheduled_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = current_user.messages
      .where(client_id: params["client_id"])
      .where('send_at < ? OR send_at IS NULL', Time.now)
      .order('created_at ASC')
    @messages.update_all(read: true)

    @messages_scheduled = current_user.clients.find(params["client_id"]).messages.scheduled
  end
end
