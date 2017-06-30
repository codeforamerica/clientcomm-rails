class FakeTwilioClient
  # source: https://robots.thoughtbot.com/testing-sms-interactions
  FakeMessage = Struct.new(:from, :to, :body)
  FakeResponse = Struct.new(:sid, :status)

  cattr_accessor :messages
  self.messages = []

  def initialize(_account_sid, _auth_token)
  end

  def messages
    self
  end

  def account
    self
  end

  def create(from:, to:, body:, statusCallback:)
    self.class.messages << FakeMessage.new(from, to, body)
    # return a fake response
    FakeResponse.new(SecureRandom.hex(17), ["accepted", "queued", "sending", "sent", "receiving", "received", "delivered"].sample)
  end
end
