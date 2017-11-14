class ScheduledMessagesChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user.clients.pluck(:id).include? params[:client_id]
    stream_from "scheduled_messages_#{params[:client_id]}"
  end
end
