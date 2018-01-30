class ReportingRelationshipsController < ApplicationController
  before_action :authenticate_user!

  def create
    if reporting_relationship_params['user_id'].blank?
      redirect_to(edit_client_path(reporting_relationship_params['client_id'])) && return
    end

    ReportingRelationship.find_by(user: current_user.id, client_id: reporting_relationship_params['client_id'])
                         .update!(active: false)

    ReportingRelationship.find_or_create_by(reporting_relationship_params).update!(active: true)

    transferred_by = 'user'

    user = User.find(reporting_relationship_params['user_id'])
    client = Client.find(reporting_relationship_params['client_id'])

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: current_user,
      client: client,
      transfer_note: transfer_note,
      transferred_by: transferred_by
    ).deliver_later

    analytics_track(
      label: :client_transfer,
      data: {
        admin_id: nil,
        clients_transferred_count: 1,
        transferred_by: transferred_by,
        has_transfer_note: transfer_note.present?
      }
    )

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

  def transfer_note
    params['transfer_note']
  end

  def reporting_relationship_params
    params.require(:reporting_relationship).permit(:user_id, :client_id)
  end
end
