class MassMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
    @mass_message = MassMessage.new
    @clients = current_user.clients
  end

  def create
    mass_message = MassMessage.new(mass_message_params.merge(user: current_user))
    mass_message.send_to_all
  end

  private

  def mass_message_params
    params.require(:mass_message).permit(:message, clients: [])
  end
end
