module Messages
  class ReadsController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :intercom_rails_auto_include

    def create
      message = current_user.messages.update(params[:message_id], read: message_params[:read])
      if message.reporting_relationship.messages.unread.empty?
        message.reporting_relationship.update!(has_unread_messages: false)
        user = message.reporting_relationship.user
        if user.reporting_relationships.active.where(has_unread_messages: true).empty?
          user.update!(has_unread_messages: false)
        end
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
