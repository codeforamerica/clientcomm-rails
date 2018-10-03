class MergeReportingRelationshipsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    rr_current = ReportingRelationship.find_by(
      user: current_user,
      client: Client.find(merge_params[:client_id])
    )
    rr_selected = ReportingRelationship.find_by(
      user: current_user,
      client: Client.find(merge_params[:selected_client_id])
    )

    chosen_phone_number_client_id = merge_params[:merge_clients][:phone_number].to_i
    rr_to, rr_from = if chosen_phone_number_client_id == rr_current.client.id
                       [rr_current, rr_selected]
                     else
                       [rr_selected, rr_current]
                     end

    to_full_name = rr_to.client.full_name
    from_full_name = rr_from.client.full_name

    chosen_full_name_client_id = merge_params[:merge_clients][:full_name].to_i
    if chosen_full_name_client_id == rr_from.client.id
      rr_to.client.update!(first_name: rr_from.client.first_name, last_name: rr_from.client.last_name)
      NotificationSender.notify_users_of_changes(user: current_user, client: rr_to.client)
    end

    Message.create_conversation_ends_marker(
      reporting_relationship: rr_from,
      full_name: from_full_name,
      phone_number: rr_from.client.display_phone_number
    )

    rr_from.messages.each do |message|
      message.update!(reporting_relationship: rr_to)
      # TODO: account for like messages!
    end

    # TODO: merge category, status, notes on reporting relationships (prefer values on rr_to in a conflict)
    # TODO: set unread on new rr, user to match messages status

    rr_from.update!(active: false)

    Message.create_merged_with_marker(
      reporting_relationship: rr_to,
      from_full_name: from_full_name,
      to_full_name: to_full_name,
      from_phone_number: rr_from.client.display_phone_number,
      to_phone_number: rr_to.client.display_phone_number
    )

    # TODO: catch errors; if anything doesn't work; redirect to edit form and flash error message

    flash[:notice] = I18n.t('flash.notices.merge')

    redirect_to reporting_relationship_path rr_to
  end

  private

  def merge_params
    params.require(:merge_reporting_relationship)
          .permit(:client_id, :selected_client_id, merge_clients: %i[full_name phone_number])
  end
end
