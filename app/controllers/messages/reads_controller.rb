module Messages
  class ReadsController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :intercom_rails_auto_include

    def create
      begin
        message = current_user.messages.update(params[:message_id], read: message_params[:read])
      rescue ActiveRecord::StaleObjectError
        Rails.logger.warn('StaleObjectError on ReadsController create')
      else
        message.reporting_relationship.update!(has_unread_messages: false)
      end
      head :no_content
    end

    private

    def message_params
      params.require(:message)
            .permit(:read)
    end
  end
end
