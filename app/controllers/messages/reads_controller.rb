class Messages::ReadsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    current_user.messages.find params[:message_id]

    # change the read status of the message
    message = Message.update(params[:message_id], read: message_params[:read])
    message.client.update!(has_unread_messages: false)

    head :no_content
  end

  private

  def message_params
    params.require(:message)
      .permit(:read)
  end
end
