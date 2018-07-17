class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user.id == params[:user_id]
    stream_from "notifications_#{params[:user_id]}"
  end
end
