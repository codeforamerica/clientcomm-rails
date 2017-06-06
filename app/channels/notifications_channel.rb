class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{params[:user_id]}"
  end
end
