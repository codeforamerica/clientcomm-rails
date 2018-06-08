FactoryBot.define do
  factory :client_edit_marker do
    reporting_relationship { create :reporting_relationship }
    body { "i am a client edit marker #{SecureRandom.hex(17)}" }
  end
end
