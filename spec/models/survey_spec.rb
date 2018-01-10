require 'rails_helper'

RSpec.describe Survey, type: :model do
  let!(:user) { create :user }
  let!(:client) { create :client, user: user }
  let!(:survey) { create :survey, user: user, client: client }

  it { should belong_to :user }
  it { should belong_to :client }
  it { should have_many(:survey_responses).through(:survey_response_links) }

  describe '#questions' do
    before do
      create_list :survey_question, 2 do |question|
        survey.survey_responses << create_list(:survey_response, 3, survey_question: question)
      end
    end

    it 'returns only the unique questions for the survey' do
      expect(survey.questions.count).to eq(2)
      expect(survey.questions).to contain_exactly(SurveyQuestion.first, SurveyQuestion.last)
    end
  end

  describe 'Nested Object Creation' do
  end
end
