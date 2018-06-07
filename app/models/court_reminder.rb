class CourtReminder < TextMessage
  belongs_to :court_date_csv
  validates :court_date_csv, presence: true
end
