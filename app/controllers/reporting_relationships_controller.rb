class ReportingRelationshipsController < ApplicationController
  before_action :authenticate_user!

  def create
    @reporting_relationship = ReportingRelationship
                              .find_by(user: current_user.id, client_id: reporting_relationship_params['client_id'])

    @client = Client.find(reporting_relationship_params['client_id'])
    @transfer_users = current_user.department.eligible_users.active
                                  .where.not(id: current_user.id)
                                  .order(:full_name).pluck(:full_name, :id)

    @transfer_reporting_relationship = ReportingRelationship.find_or_initialize_by(reporting_relationship_params)
    @transfer_reporting_relationship.active = true

    begin
      ActiveRecord::Base.transaction do
        @reporting_relationship.update!(active: false)
        @transfer_reporting_relationship.save!
      end
    rescue ActiveRecord::RecordInvalid
      render 'clients/edit'
      return
    end

    transferred_by = 'user'

    user = User.find(reporting_relationship_params['user_id'])

    @client.messages.scheduled.where(user: current_user).update(user: user)

    if current_user == current_user.department.unclaimed_user
      unclaimed_messages = @client.messages.where(user: current_user)
      unclaimed_messages.update(user: user)
    end

    NotificationMailer.client_transfer_notification(
      current_user: user,
      previous_user: current_user,
      client: @client,
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
        client_full_name: @client.full_name,
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
