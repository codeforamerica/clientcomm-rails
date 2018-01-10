require 'rails_helper'

RSpec.describe SurveyResponseLink, type: :model do
  it { should belong_to :survey }
  it { should belong_to :survey_response }
end
