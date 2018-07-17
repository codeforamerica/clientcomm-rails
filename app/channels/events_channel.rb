class EventsChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user.id == params[:user_id]
    stream_from "events_#{current_user.id}"
  end
end
