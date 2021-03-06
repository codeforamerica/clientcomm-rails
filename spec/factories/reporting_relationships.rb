FactoryBot.define do
  factory :reporting_relationship do
    user { create :user }
    client { create :client }
    category { ReportingRelationship::CATEGORIES.keys.first }
  end
end
