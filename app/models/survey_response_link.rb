class SurveyResponseLink < ApplicationRecord
  belongs_to :survey
  belongs_to :survey_response
end
