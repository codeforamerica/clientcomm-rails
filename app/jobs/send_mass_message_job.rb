class SendMassMessageJob < ApplicationJob
  queue_as :default

  def perform(body:, send_at:, rrs:)
    send_at_or_now = Time.zone.parse(send_at) || Time.zone.now
    rrs.each do |rr_id|
      rr = ReportingRelationship.find(rr_id)
      message = TextMessage.create!(
        body: body,
        reporting_relationship: rr,
        read: true,
        inbound: false,
        send_at: send_at_or_now
      )

      message.send_message
      if send_at > Time.zone.now
        track(
          label: 'message_scheduled',
          user_id: rr.user.id,
          data: message.analytics_tracker_data.merge(mass_message: true)
        )
      else
        track(
          label: 'message_send',
          user_id: rr.user.id,
          data: message.analytics_tracker_data.merge(mass_message: true)
        )
      end
    end
  end

  private

  def track(label:, user_id:, data: {})
    tracking_data = {
      deploy: deploy_prefix
    }.merge(data)
    AnalyticsService.track(
      label: label,
      distinct_id: distinct_id(user_id),
      data: tracking_data
    )
  end

  def deploy_prefix
    URI.parse(ENV['DEPLOY_BASE_URL']).hostname.split('.')[0..1].join('_')
  end

  def distinct_id(user_id)
    "#{deploy_prefix}-admin_#{user_id}"
  end
end
