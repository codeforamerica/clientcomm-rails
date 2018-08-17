class CleanupMessageHistory < ActiveRecord::Migration[5.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    past_messages = TextMessage.where(sent: false).where(inbound: false).where('send_at < ?', Time.zone.now - 1.hour)
    past_messages.where.not(twilio_sid: nil).update_all(sent: true)
    past_messages.where(twilio_sid: nil).update_all(twilio_status: 'undelivered', sent: true)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
