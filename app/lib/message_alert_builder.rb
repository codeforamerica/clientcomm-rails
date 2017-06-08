
class MessageAlertBuilder
  include Rails.application.routes.url_helpers

  def build(user:)
    # return an alert appropriate for the state of unread messages
    # messages where read = false and user = current_user
    unread_messages = user.messages.where(read: false)
    if unread_messages.length == 0
      nil
    else
      lookup = user.messages.group(:client).count
      if lookup.length == 1
        client = lookup.keys.first
        {
          text: "You have an unread message from #{client.full_name}",
          link_to: client_messages_path(client)
        }
      else
        nil
      end
    end

    # "You have an unread message from Donald Duck"
    # "You have 5 unread messages from Donald Duck"
    # "You have 12 unread messages"

  end
end