require 'rails_helper'

describe 'tracking_events', type: :request do
  describe 'tracking_events#create' do
    let(:headers) { { 'ACCEPT' => 'application/json' } }
    let(:params) { {} }
    subject do
      post tracking_events_path, params: params, headers: headers
    end

    it 'rejects unauthenticated events' do
      subject
      expect(response.code).to eq('401')
    end

    context 'with a logged-in user' do
      let(:user) { create :user }
      let(:params) { { label: 'foo', data: { 'key' => 'value' } } }

      before do
        sign_in user
      end

      it 'tracks the submitted event' do
        subject
        expect(response.code).to eq('204')
        expect_most_recent_analytics_event('foo' => { 'key' => 'value' })
      end
    end
  end
end
