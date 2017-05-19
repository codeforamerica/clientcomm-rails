class SMSService
  def initialize
    @client = Twilio::REST::Client.new(
      ENV['TWILIO_ACCOUNT_SID'] 
      ENV['TWILIO_AUTH_TOKEN']
    )
  end

  def send_message(from:, to:, body:)
    clean_to = clean_phone_number(to)
    @client.messages.create(from: from, to: clean_to, body: body)
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
