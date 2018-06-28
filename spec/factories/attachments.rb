FactoryBot.define do
  factory :attachment do
    message { build :text_message }
    media { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'fluffy_cat.jpg'), 'image/png') }
  end
end
