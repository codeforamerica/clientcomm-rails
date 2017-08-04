class Messages::ReadsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    # change the read status of the message
    message.update!(read: message_params[:read])

    head :no_content
  end

  private

  def message
    current_user.messages.find params[:message_id]
  end

  def message_params
    params.require(:message)
      .permit(:read)
  end
end
