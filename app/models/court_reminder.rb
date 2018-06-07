class CourtReminder < TextMessage
  belongs_to :court_date_csv

  before_validation :set_outbound, on: :created
  validates :court_date_csv, presence: true

  private

  def set_marker
    self.inbound = false
    self.send_at = Time.current
  end
end
