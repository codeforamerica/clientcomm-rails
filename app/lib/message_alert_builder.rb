
class MessageAlertBuilder
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TextHelper

  def build(user:)
    # return an alert appropriate for the state of unread messages
    unread_messages = user.messages.where(read: false)
    if unread_messages.length == 0
      nil
    else
      lookup = user.messages.group(:client).count
      if lookup.length == 1
        client = lookup.keys.first
        message_count = lookup.values.first
        {
          text: "You have #{pluralize(message_count, 'unread message')} from #{client.full_name}",
          link_to: client_messages_path(client)
        }
      else
        message_count = lookup.values.sum
        {
          text: "You have #{pluralize(message_count, 'unread message')}",
          link_to: clients_path
        }
      end
    end
  end
end
