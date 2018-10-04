class ConversationEndsMarker < Marker
  private

  def set_marker
    self.inbound = true
    self.read = true
  end
end
