FactoryBot.define do
  factory :change_image do
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'fluffy_cat.jpg'), 'image/png') }
    admin_user { create :admin_user }
  end
end
