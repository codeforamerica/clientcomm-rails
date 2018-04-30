class ScheduledMessagesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def index
    rr = current_user.reporting_relationships.find params[:reporting_relationship_id]
    @client = rr.client
    @templates = current_user.templates

    reporting_relationship = @client.reporting_relationship(user: current_user)

    analytics_track(
      label: 'client_scheduled_messages_view',
      data: @client.analytics_tracker_data.merge(reporting_relationship.analytics_tracker_data)
    )

    # the list of past messages
    @messages = reporting_relationship.messages
                                      .where('send_at < ? OR send_at IS NULL', Time.zone.now)
                                      .order('created_at ASC')
    @messages.where(read: false).update(read: true)

    @messages_scheduled = reporting_relationship.messages.scheduled
  end
end
