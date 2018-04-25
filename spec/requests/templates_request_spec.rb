require 'rails_helper'

describe 'Templates requests', type: :request do
  context 'unauthenticated' do
    it 'rejects unauthenticated user' do
      get templates_path
      expect(response.code).to eq '302'
      expect(response).to redirect_to new_user_session_path
    end
  end

  context 'authenticated' do
    let(:user) { create :user }

    before do
      sign_in user
    end

    describe 'GET#index' do
      before do
        create_list :template, 5, user: user
      end

      subject { get templates_path }

      it 'returns a list of templates' do
        subject

        user.templates.each do |template|
          expect(Nokogiri.parse(response.body).to_s).to include("#{template.title}")
          expect(Nokogiri.parse(response.body).to_s).to include("#{template.body}")
        end

        expect_analytics_events({
                                  'template_page_view' => {
                                    'templates_count' => 5
                                  }
                                })
      end
    end

    describe 'POST#create' do
      let(:title) { Faker::Lorem.sentence }
      let(:body) { Faker::Lorem.characters 50 }

      before do
        post templates_path, params: {
          template: {
            title: title,
            body: body
          }
        }
      end

      it 'creates a template' do
        expect(response.code).to eq '302'
        expect(response).to redirect_to templates_path

        expect_analytics_events({
                                  'template_create_success' => {
                                    'message_length' => 50
                                  }
                                })
      end

      context 'receives invalid template parameters' do
        let(:title) { nil }

        it 'renders new with validation errors' do
          expect(response.code).to eq '200'
          expect(response.body).to include 'Give your template a name so you can find it in the list.'
          expect(Template.count).to eq 0
        end
      end
    end

    describe 'PUT#update' do
      let!(:template) { create :template, user_id: user.id, title: 'Old title', body: 'Old body' }

      it 'starts with the correct values' do
        expect(template.title).to eq 'Old title'
        expect(template.title).to eq 'Old title'
      end

      it 'updates the template' do
        patch template_path(template.id), params: {
          template: {
            title: 'New title',
            body: 'New body'
          }
        }

        expect(response.code).to eq '302'
        expect(response).to redirect_to templates_path

        get templates_path

        expect(Nokogiri.parse(response.body).to_s).to include('New title')
        expect(Nokogiri.parse(response.body).to_s).to include('New body')
      end
    end

    describe 'DELETE#destroy' do
      let!(:template) { create :template, user_id: user.id, title: 'Delete title', body: 'Delete body' }

      it 'deletes the template' do
        delete template_path(template)
        expect(response.code).to eq '302'
        expect(response).to redirect_to templates_path

        expect_analytics_events({
                                  'template_delete' => {
                                    'templates_count' => 0
                                  }
                                })
      end
    end
  end
end
