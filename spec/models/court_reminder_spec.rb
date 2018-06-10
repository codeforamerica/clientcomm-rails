require 'rails_helper'

describe CourtReminder, type: :model do
  it { should belong_to :court_date_csv }
  # it { should validate_presence_of :court_date_csv }
end
