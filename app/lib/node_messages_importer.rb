module NodeMessagesImporter
  def self.import_message(message_segments)
    node_message = message_segments.first
    body = node_message['content']
    user = User.find_by(node_id: node_message['cm'])
    client = Client.find_by(node_comm_id: node_message['comm'])
    rr = ReportingRelationship.find_by(user: user, client: client)

    return if rr.nil?

    normalized_phone_number = "+#{node_message['value']}"

    message = Message.new(
      body: body,
      inbound: node_message['inbound'],
      number_from: node_message['inbound'] == 't' ? normalized_phone_number : rr.department.phone_number,
      number_to: node_message['inbound'] == 't' ? rr.department.phone_number : normalized_phone_number,
      read: node_message['read'],
      reporting_relationship: rr,
      send_at: node_message['created'],
      twilio_sid: node_message['tw_sid'],
      twilio_status: node_message['tw_status']
    )

    message.save!
  end
end
