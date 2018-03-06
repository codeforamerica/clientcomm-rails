class MassMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
    @mass_message = MassMessage.new(params.permit(:message, clients: []))
    @clients = SortClients.mass_messages_list(user: current_user, selected_clients: @mass_message.clients)

    analytics_track(
      label: 'mass_message_compose_view',
      data: {
        clients_count: @clients.count
      }
    )
  end

  def create
    mass_message = MassMessage.new(mass_message_params.merge(user: current_user))
    mass_message.clients = mass_message.clients.reject(&:zero?)

    if mass_message.invalid?
      @mass_message = mass_message
      @clients = SortClients.mass_messages_list(user: current_user)

      render :new
      return
    end

    send_mass_message(mass_message)
    if mass_message.send_at.present?
      flash[:notice] = I18n.t('flash.notices.mass_message.scheduled')
      analytics_track(
        label: 'mass_message_scheduled',
        data: {
          recipients_count: mass_message.clients.count
        }
      )
    else
      flash[:notice] = I18n.t('flash.notices.mass_message.sent')
      analytics_track(
        label: 'mass_message_send',
        data: {
          recipients_count: mass_message.clients.count
        }
      )
    end
    redirect_to clients_path
  end

  private

  def send_mass_message(mass_message)
    mass_message.clients.each do |client_id|
      client = current_user.clients.find(client_id)
      send_at = mass_message.send_at || Time.now
      message = Message.create!(
        body: mass_message.message,
        user: mass_message.user,
        client: client,
        number_from: current_user.department.phone_number,
        number_to: client.phone_number,
        read: true,
        inbound: false,
        send_at: send_at
      )

      message.send_message
      if mass_message.send_at.present?
        analytics_track(
          label: 'message_scheduled',
          data: message.analytics_tracker_data.merge(mass_message: true)
        )
      else
        analytics_track(
          label: 'message_send',
          data: message.analytics_tracker_data.merge(mass_message: true)
        )
      end
    end
  end

  def mass_message_params
    params.require(:mass_message).permit(:message, :send_at, clients: [])
  end
end
