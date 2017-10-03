class MassMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
    @mass_message = MassMessage.new
    @clients = SortClients.run(user: current_user)

    analytics_track(
      label: 'mass_message_compose_view',
      data: {
        clients_count: @clients.count
      }
    )
  end

  def create
    mass_message = MassMessage.new(mass_message_params.merge(user: current_user))
    mass_message.clients = mass_message.clients.reject(&:empty?)

    if mass_message.invalid?
      @mass_message = mass_message
      @clients = SortClients.run(user: current_user)

      render :new
      return
    end

    send_mass_message(mass_message)

    flash[:notice] = 'Your mass message has been sent.'

    analytics_track(
      label: 'mass_message_send',
      data: {
        recipients_count: mass_message.clients.count
      }
    )

    redirect_to clients_path
  end

  private

  def send_mass_message(mass_message)
    mass_message.clients.each do |client_id|
      client = Client.find(client_id)

      message = Message.create!(
        body: mass_message.message,
        user: mass_message.user,
        client: client,
        number_from: ENV['TWILIO_PHONE_NUMBER'],
        number_to: client.phone_number,
        read: true,
        inbound: false,
        send_at: Time.now
      )

      ScheduledMessageJob.perform_later(message: message, send_at: message.send_at.to_i, callback_url: incoming_sms_status_url)

      analytics_track(
        label: 'message_send',
        data: message.analytics_tracker_data.merge(mass_message: true)
      )
    end
  end

  def mass_message_params
    params.require(:mass_message).permit(:message, clients: [])
  end
end
