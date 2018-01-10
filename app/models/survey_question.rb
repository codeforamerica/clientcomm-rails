class SurveyQuestion < ApplicationRecord
  has_many :survey_responses, dependent: :nullify
end
