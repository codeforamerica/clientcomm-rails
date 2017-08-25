require 'rails_helper'

describe VoiceService do
  describe '#generate_twiml' do
    it 'takes a string and responds with twiml' do
      response = subject.generate_twiml(message: 'Hello there')
      expect(response).to eq '<?xml version="1.0" encoding="UTF-8"?><Response><Say voice="woman">Hello there</Say></Response>'
    end
  end
end
