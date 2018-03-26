module MessageAlertBuilder
  extend ActionView::Helpers::TextHelper

  def self.build_alert(reporting_relationship:, reporting_relationship_path:, clients_path:)
    # return an alert appropriate for the state of unread messages
    unread_messages = reporting_relationship.user.messages.unread
    if unread_messages.empty?
      nil
    else
      lookup = unread_messages.group(:reporting_relationship).count
      if lookup.length == 1
        rr = lookup.keys.first
        message_count = lookup.values.first
        {
          text: "You have #{pluralize(message_count, 'unread message')} from #{rr.client.full_name}",
          link_to: reporting_relationship_path
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
