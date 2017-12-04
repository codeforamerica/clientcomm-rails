class Messages::ReadsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    message = current_user.messages.update(params[:message_id], read: message_params[:read])

    ReportingRelationship.find_by(client: message.client, user: message.user).update!(has_unread_messages: false)

    head :no_content
  end

  private

  def message_params
    params.require(:message)
          .permit(:read)
  end
end
