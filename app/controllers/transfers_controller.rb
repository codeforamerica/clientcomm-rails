class TransfersController < ApplicationController
  before_action :authenticate_user!

  def create
    unless transfer_params['user_id'].present?
      redirect_to(edit_client_path(transfer_params['client_id'])) && return
    end
    user = User.find(transfer_params['user_id'])
    client = Client.find(transfer_params['client_id'])
    transfer_note = transfer_params['note']
    transfer = Transfer.new(user_id: user.id, client_id: client.id, note: transfer_note)
    transfer.apply

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: current_user,
      client: client,
      transfer_note: transfer_note
    ).deliver_later

    redirect_to(
      clients_path,
      notice: t(
        'flash.notices.client.transferred',
        client_full_name: client.full_name,
        user_full_name: user.full_name
      )
    )
  end

  private

  def transfer_params
    params.require(:transfer)
  end
end
