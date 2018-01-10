require 'rails_helper'

RSpec.describe SurveyQuestion, type: :model do
  it { should have_many :survey_responses }
end
