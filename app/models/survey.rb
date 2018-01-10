class Survey < ApplicationRecord
  belongs_to :client
  belongs_to :user
  has_many :survey_response_links, dependent: :nullify
  has_many :survey_responses, through: :survey_response_links

  def questions
    survey_responses.map(&:survey_question).uniq
  end
end
