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

    failed = reporting_relationships_invalid?(rr_to, rr_from)

    unless failed
      begin
        copy_name = merge_params[:merge_clients][:full_name].to_i == rr_from.client.id
        rr_to.merge_with(rr_from, copy_name)
      rescue ActiveRecord::RecordInvalid
        failed = true
      end
    end

    tracking_data = { selected_client_id: rr_selected&.client&.id }

    if failed
      flash[:alert] = I18n.t('flash.errors.merge.invalid')
      redirect_to edit_client_path rr_current.client

      analytics_track(
        label: 'client_merge_error',
        data: rr_current.client.analytics_tracker_data.merge(tracking_data)
      )

      return
    end

    tracking_data[:preserved_client_id] = rr_to.client.id

    analytics_track(
      label: 'client_merge_success',
      data: rr_current.client.analytics_tracker_data.merge(tracking_data)
    )

    flash[:notice] = I18n.t('flash.notices.merge')
    redirect_to reporting_relationship_path rr_to
  end

  private

  def reporting_relationships_invalid?(rr_to, rr_from)
    rr_to.nil? || rr_from.nil? || rr_to.active == false || rr_from.active == false
  end

  def merge_params
    params.require(:merge_reporting_relationship)
          .permit(:client_id, :selected_client_id, merge_clients: %i[full_name phone_number])
  end
end
