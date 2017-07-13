class ScheduledMessageJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  def perform(user, client_id, message_body, callback_url:)
    send_message(user, client_id, message_body, callback_url: callback_url)
  end
end
