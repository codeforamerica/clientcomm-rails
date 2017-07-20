class ScheduledMessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "scheduled_messages_#{params[:client_id]}"
  end
end
