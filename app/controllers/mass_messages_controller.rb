class MassMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
    @mass_message = MassMessage.new
    @clients = SortClients.run(user: current_user)
  end

  def create
    mass_message = MassMessage.new(mass_message_params.merge(user: current_user))
    SMSService.instance.send_mass_message(mass_message: mass_message, callback_url: incoming_sms_status_url)

    flash[:notice] = 'Your mass message has been sent.'

    redirect_to clients_path
  end

  private

  def mass_message_params
    params.require(:mass_message).permit(:message, clients: [])
  end
end
