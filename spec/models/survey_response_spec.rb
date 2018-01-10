require 'rails_helper'

RSpec.describe SurveyResponse, type: :model do
  it { should belong_to(:survey_question) }
  it { should have_many(:survey_response_links) }
end
