class Marker < Message
  before_validation :set_marker, on: :created

  private

  def set_marker
    self.inbound = true
    self.send_at = Time.current
  end
end
