class ReadsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    # change the read status of the message
    success = message.update_attributes read: message_params[:read]
    if success
      head :no_content
    else
      head :bad_request
    end
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
