FactoryBot.define do
  factory :attachment do
    message { build :text_message }
  end
end
