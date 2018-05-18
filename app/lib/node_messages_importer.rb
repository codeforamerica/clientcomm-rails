module NodeMessagesImporter
  def self.import_message(message_segments)
    content_parts = []
    message_segments.each do |segment|
      content_parts << segment['content']
    end
    body = content_parts.join
    first_segment = message_segments.first
    user = User.find_by(node_id: first_segment['cm'])
    client = Client.find_by(node_comm_id: first_segment['comm'])
    rr = ReportingRelationship.find_by(user: user, client: client)

    return if rr.nil?

    normalized_phone_number = "+#{first_segment['value']}"
    inbound = first_segment['inbound'] == 't'

    message = Message.new(
      body: body,
      inbound: first_segment['inbound'],
      number_from: inbound ? normalized_phone_number : rr.department.phone_number,
      number_to: inbound ? rr.department.phone_number : normalized_phone_number,
      read: inbound ? first_segment['read'] : true,
      reporting_relationship: rr,
      send_at: first_segment['created'],
      twilio_sid: first_segment['tw_sid'],
      twilio_status: first_segment['tw_status']
    )

    message.save!
  end
end
