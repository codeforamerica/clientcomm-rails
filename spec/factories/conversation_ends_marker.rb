FactoryBot.define do
  factory :conversation_ends_marker do
    reporting_relationship { create :reporting_relationship }
    body { "i am a 'conversation ends' marker #{SecureRandom.hex(17)}" }
  end
end
