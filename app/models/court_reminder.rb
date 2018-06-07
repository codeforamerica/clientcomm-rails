class CourtReminder < TextMessage
  before_validation :set_outbound, on: :created

  private

  def set_marker
    self.inbound = false
    self.send_at = Time.current
  end
end
