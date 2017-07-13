require 'singleton'

class SMSService
  include Singleton

  def initialize
    sid = ENV['TWILIO_ACCOUNT_SID']
    token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new sid, token
  end

  def send_message(user, client_id, message_body, callback_url:)
    client = user.clients.find client_id

    # send the message via Twilio
    response = send_twilio_message(
        to: client.phone_number,
        body: message_body,
        callback_url: callback_url
    )

    # save the message
    new_message = Message.create(
        body: message_body,
        client: client,
        inbound: false,
        number_from: ENV['TWILIO_PHONE_NUMBER'],
        number_to: client.phone_number,
        read: true,
        twilio_sid: response.sid,
        twilio_status: response.status,
        user: user
    )

    # put the message broadcast in the queue
    MessageBroadcastJob.perform_now(message: new_message, is_update: false)

    new_message
  end

  private

  def send_twilio_message(from: nil, to:, body:, callback_url:)
    to_clean = PhoneNumberParser.normalize(to)
    # use the from in the ENV if one wasn't sent
    from ||= ENV['TWILIO_PHONE_NUMBER']
    from_clean = PhoneNumberParser.normalize(from)
    @client.account.messages.create(
        from: from_clean,
        to: to_clean,
        body: body,
        statusCallback: callback_url
    )
  end
end
