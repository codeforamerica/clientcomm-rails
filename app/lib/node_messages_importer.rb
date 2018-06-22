module NodeMessagesImporter
  # rubocop:disable Metrics/PerceivedComplexity
  def self.import_message(message_segments)
    return if Message.find_by(twilio_sid: message_segments.first['tw_sid']).present?

    body, segment, user, client, rr = nil
    message_groups = message_segments.group_by { |s| s['convid'] }
    message_groups.each_key do |convid|
      body = message_groups[convid].map { |s| s['content'] }.join
      segment = message_groups[convid].first
      user = User.find_by(node_id: segment['cm'])
      client = Client.find_by(node_comm_id: segment['comm'])
      rr = ReportingRelationship.find_by(user: user, client: client)
      break if rr.present?
    end

    return if rr.nil? || body.blank?

    normalized_phone_number = "+#{segment['value']}"
    inbound = segment['inbound'] == 't'
    sent = !inbound

    message = TextMessage.new(
      body: body,
      inbound: segment['inbound'],
      number_from: inbound ? normalized_phone_number : rr.department.phone_number,
      number_to: inbound ? rr.department.phone_number : normalized_phone_number,
      read: inbound ? segment['read'] : true,
      reporting_relationship: rr,
      send_at: segment['created'],
      sent: sent,
      twilio_sid: segment['tw_sid'],
      twilio_status: segment['tw_status']
    )

    if segment['tw_sid'].starts_with?('RE')
      attachment = Attachment.new

      attachment.media_file("https://api.twilio.com/2010-04-01/Accounts/#{ENV['TWILIO_ACCOUNT_SID']}/Recordings/#{segment['tw_sid']}")
      message.attachments << attachment
    end

    message.save!
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
