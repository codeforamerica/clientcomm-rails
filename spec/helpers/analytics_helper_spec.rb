require 'rails_helper'
RSpec.describe AnalyticsHelper, type: :helper do
  context '#analytics_track' do
    let(:helper_class) do
      Class.new do
        attr_reader :request

        include AnalyticsHelper

        def initialize(request, user)
          @request = request
          @user = user
        end

        def current_user
          @user
        end
      end
    end
    let(:treatment_group) { 'la lal la' }
    let(:user) { create :user, treatment_group: treatment_group }
    let(:request) {
      double(
        'request',
        GET: { 'utm_token' => 'utm token', 'token' => 'not token' },
        env: { 'HTTP_USER_AGENT' => '11.1.1.1' },
        remote_ip: '10.1.1.1',
        base_url: 'http://test'
      )
    }
    subject do
      helper_class.new(request, user).analytics_track(
        label: 'test_label', data: {}
      )
    end

    it 'includes treamentgroup' do
      subject
      expect_analytics_events('test_label' => { 'treatment_group' => treatment_group })
    end

    it 'includes utm data if it is in the request' do
      subject
      expect_analytics_events('test_label' => { 'utm_token' => 'utm token' })
    end

    it 'does not includes non utm from the request' do
      subject
      expect_not_in_analytics_events('test_label' => { 'token' => 'not token' })
    end
  end
end
