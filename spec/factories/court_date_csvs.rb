FactoryBot.define do
  factory :court_date_csv do
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'court_dates.csv'), 'text/csv') }
    user { create :user }
  end
end
