class MessagesController < ApplicationController
  def index
    @messages = current_user.messages.where(client_id: params["client_id"]).order('created_at ASC')
  end
end
