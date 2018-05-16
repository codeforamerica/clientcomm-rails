module NodeMessagesImporter
  def self.import_message(message_segments)
    node_message = message_segments.first
    body = node_message['content']
    user = User.find_by(node_id: node_message['cm'])
    client = Client.find_by(node_comm_id: node_message['comm'])
    send_at = Time.parse(node_message['created']).utc
    rr = ReportingRelationship.find_by(user: user, client: client)

    return if rr.nil?

    message = Message.new(
      body: body,
      inbound: ActiveModel::Type::Boolean.new.cast(node_message['inbound']),
      number_from: "+#{node_message['value']}",
      number_to: rr.department.phone_number,
      read: ActiveModel::Type::Boolean.new.cast(node_message['read']),
      reporting_relationship: rr,
      send_at: send_at,
      twilio_sid: node_message['tw_sid'],
      twilio_status: node_message['tw_status']
    )

    message.save!
  end
end
