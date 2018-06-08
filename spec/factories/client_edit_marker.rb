FactoryBot.define do
  factory :client_edit_marker do
    reporting_relationship { create :reporting_relationship }
    body { "i am a message #{SecureRandom.hex(17)}" }
  end
end
