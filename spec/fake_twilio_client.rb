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
    FakeResponse.new(SecureRandom.hex(17), ["queued", "sending", "sent", "failed", "received"].sample)
  end
end
