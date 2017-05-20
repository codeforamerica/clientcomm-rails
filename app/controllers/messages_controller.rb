class MessagesController < ApplicationController
  def index
    # the client being messaged
    @client = Client.find params[:client_id]
    # the list of past messages
    @messages = current_user.messages.where(client_id: params["client_id"]).order('created_at ASC')
    # a new message for the form
    @message = Message.new
  end
end
