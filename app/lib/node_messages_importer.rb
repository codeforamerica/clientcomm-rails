module NodeMessagesImporter
  def self.import_message(message_segments)
    node_message = message_segments.first
    body = node_message['content']
    user = User.find_by(node_id: node_message['cm'])
    client = Client.find_by(node_comm_id: node_message['comm'])
    rr = ReportingRelationship.find_by(user: user, client: client)

    return if rr.nil?

    message = Message.new(
      reporting_relationship: rr,
      number_to: rr.department.phone_number,
      number_from: client.phone_number,
      inbound: true,
      twilio_sid: '',
      twilio_status: '',
      body: body,
      send_at: Time.current
    )

    message.save!
  end
end
