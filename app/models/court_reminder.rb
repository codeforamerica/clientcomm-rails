class CourtReminder < TextMessage
  belongs_to :court_date_csv

  before_validation :set_court_reminder, on: :create
  validates :court_date_csv, presence: true

  private

  def set_court_reminder
    self.inbound = false
    self.read = true
  end
end
