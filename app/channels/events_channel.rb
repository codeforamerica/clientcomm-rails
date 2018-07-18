class EventsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "events_#{current_user.id}"
  end
end
