class ScheduledMessagesController < ApplicationController
  def index
    @client = current_user.clients.find params[:client_id]

    analytics_track(
      label: 'client_messages_view',
      data: @client.analytics_tracker_data
    )

    # the list of past messages
    @messages = current_user.messages
      .where(client_id: params["client_id"])
      .where('send_at < ? OR send_at IS NULL', Time.now)
      .order('created_at ASC')
    @messages.update_all(read: true)

    @messages_scheduled = current_user.messages
      .where(client_id: params["client_id"])
      .where('send_at >= ?', Time.now)
      .order('created_at ASC')
  end

end
