class CleanupMessageHistory < ActiveRecord::Migration[5.1]
  def up
    past_messages = TextMessage.where(sent: false).where(inbound: false).where('send_at < ?', Time.zone.now - 1.hour)
    past_messages.where.not(twilio_sid: nil).update(sent: true)
    past_messages.where(twilio_sid: nil).update(twilio_status: 'undelivered')
    past_messages.where(twilio_sid: nil).update(sent: true)
  end
end
