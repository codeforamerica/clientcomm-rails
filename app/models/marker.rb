class Marker < Message
  before_validation :set_marker, on: :create

  private

  def set_marker
    self.inbound = true
    self.send_at = Time.zone.now
    self.read = true
  end
end
