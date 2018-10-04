FactoryBot.define do
  factory :merged_with_marker do
    reporting_relationship { create :reporting_relationship }
    body { "i am a 'merged with' marker #{SecureRandom.hex(17)}" }
  end
end
