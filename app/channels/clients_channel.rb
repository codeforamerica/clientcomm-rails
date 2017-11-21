class ClientsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "clients_#{current_user.id}"
  end
end
