class FakeTwilioClient
  # source: https://robots.thoughtbot.com/testing-sms-interactions
  FakeResponse = Struct.new(:sid, :status)

  def initialize(_account_sid, _auth_token)
  end

  def api
    self
  end

  def messages(sid = nil)
    self
  end

  def account
    self
  end

  def fetch
    self
  end

  def update(params)
    nil
  end

  def create(from:, to:, body:, status_callback:)
    FakeResponse.new(SecureRandom.hex(17), 'delivered')
  end
end
