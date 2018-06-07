FactoryBot.define do
  factory :court_date_csv do
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'court_dates.csv'), 'text/csv') }
    admin_user { create :admin_user }
  end
end
