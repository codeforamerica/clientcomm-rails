require 'cgi'

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

  def num_media
    '0'
  end

  def media
    self
  end

  def list
    []
  end

  def account
    self
  end

  def fetch(params = nil)
    self
  end

  def update(params)
    nil
  end

  def lookups
    self
  end

  def v1
    self
  end

  def phone_numbers(phone_number)
    @phone_number = CGI.unescape(phone_number)
    self
  end

  def phone_number
    @phone_number
  end

  def create(from:, to:, body:, status_callback:)
    FakeResponse.new(SecureRandom.hex(17), 'delivered')
  end
end
