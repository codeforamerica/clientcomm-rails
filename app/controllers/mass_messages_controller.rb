class MassMessagesController < ApplicationController
  before_action :authenticate_user!

  def new
    @mass_message = MassMessage.new(params.permit(:message, reporting_relationships: []))
    @mass_message.send_at = default_send_at
    @reporting_relationships = current_user.active_reporting_relationships_with_selection(selected_reporting_relationships: @mass_message.reporting_relationships)

    analytics_track(
      label: 'mass_message_compose_view',
      data: {
        clients_count: @reporting_relationships.count
      }
    )
  end

  def create
    send_at = if params[:commit] == 'Schedule messages'
                DateParser.parse(mass_message_params[:send_at][:date], mass_message_params[:send_at][:time])
              else
                Time.zone.now
              end

    mass_message = MassMessage.new(
      reporting_relationships: mass_message_params[:reporting_relationships],
      message: mass_message_params[:message],
      user: current_user,
      send_at: send_at
    )

    mass_message.reporting_relationships = mass_message.reporting_relationships.reject(&:zero?)

    if mass_message.invalid? || mass_message.past_message?
      @mass_message = mass_message
      @reporting_relationships = current_user.active_reporting_relationships

      render :new
      return
    end

    SendMassMessageJob.perform_later(body: mass_message.message, send_at: mass_message.send_at.to_s, rrs: mass_message.reporting_relationships)

    if mass_message.send_at > Time.zone.now
      flash[:notice] = I18n.t('flash.notices.mass_message.scheduled')
      analytics_track(
        label: 'mass_message_scheduled',
        data: {
          recipients_count: mass_message.reporting_relationships.count
        }
      )
    else
      flash[:notice] = I18n.t('flash.notices.mass_message.sent')
      analytics_track(
        label: 'mass_message_send',
        data: {
          recipients_count: mass_message.reporting_relationships.count
        }
      )
    end
    redirect_to clients_path
  end

  private

  def default_send_at
    Time.current.beginning_of_day + 9.hours
  end

  def mass_message_params
    params.require(:mass_message).permit(:message, send_at: %i[date time], reporting_relationships: [])
  end
end
