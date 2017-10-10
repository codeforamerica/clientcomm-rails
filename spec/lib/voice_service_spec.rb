require 'rails_helper'

describe VoiceService do

  describe '#generate_text_response' do
    it 'takes a string and responds with twiml' do
      response = subject.generate_text_response(message: 'Hello there')
      expect(response).to eq '<?xml version="1.0" encoding="UTF-8"?><Response><Say voice="woman">Hello there</Say></Response>'
    end
  end

  describe '#dial_number' do
    it 'takes a phone number and responds with twiml to dial that number' do
      response = subject.dial_number(phone_number: '+12425551212')
      expect(response).to eq '<?xml version="1.0" encoding="UTF-8"?><Response><Dial><Number>+12425551212</Number></Dial></Response>'
    end
  end

end
