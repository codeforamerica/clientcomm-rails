class SurveyResponse < ApplicationRecord
  belongs_to :survey_question
  has_many :survey_response_links, dependent: :nullify
end
