class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "messages_#{params[:client_id]}"
  end
end
