require 'singleton'

class SMSService
  include Singleton

  def initialize
    sid = ENV['TWILIO_ACCOUNT_SID']
    token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new sid, token
  end

  def send_message(from: nil, to:, body:, callback_url:)
    to_clean = clean_phone_number(to)
    # use the from in the ENV if one wasn't sent
    from ||= ENV['TWILIO_PHONE_NUMBER']
    from_clean = clean_phone_number(from)
    @client.account.messages.create(from: from_clean, to: to_clean, body: body, statusCallback: callback_url)
  end

  private

  def clean_phone_number(phone_number)
    stripped = phone_number.to_s.gsub(/\D+/, "")
    if (stripped.length == 11) && (stripped[0] == '1')
      "+" + stripped
    else
      "+1" + stripped
    end
  end

end
