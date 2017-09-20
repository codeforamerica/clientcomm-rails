class FakeTwilioClient
  # source: https://robots.thoughtbot.com/testing-sms-interactions
  FakeMessage = Struct.new(:messaging_service_sid, :to, :body)
  FakeResponse = Struct.new(:sid, :status)

  mattr_accessor :messages
  mattr_accessor :force_status
  self.messages = []
  self.force_status = nil

  def initialize(_account_sid, _auth_token)
  end

  def v2010
    self
  end

  def api
    self
  end

  def messages
    self
  end

  def account
    self
  end

  def create(messaging_service_sid:, to:, body:)
    self.class.messages << FakeMessage.new(messaging_service_sid, to, body)
    # return a fake response
    # reply with a successful status if force_status hasn't been set
    status = self.force_status
    self.force_status = nil
    if not status
      status = ["accepted", "queued", "sending", "sent", "receiving", "received", "delivered"].sample
    end
    FakeResponse.new(SecureRandom.hex(17), status)
  end
end
