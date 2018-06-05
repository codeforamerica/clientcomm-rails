require 'rails_helper'
RSpec.describe AnalyticsHelper, type: :helper do
  context '#analytics_track' do
    let(:helper_class) do
      Class.new do
        attr_reader :request

        include AnalyticsHelper

        def initialize(request, user, admin_user)
          @request = request
          @user = user
          @admin_user = admin_user
        end

        def current_user
          @user
        end

        def current_admin_user
          @admin_user
        end
      end
    end
    let(:treatment_group) { 'la lal la' }
    let(:admin_user) { nil }
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
      helper_class.new(request, user, admin_user).analytics_track(
        label: 'test_label', data: {}
      )
    end

    before do
      @deploy_base_url = ENV['DEPLOY_BASE_URL']
      ENV['DEPLOY_BASE_URL'] = 'https://test.clientcomm.com'
    end

    after do
      ENV['DEPLOY_BASE_URL'] = @deploy_base_url
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

    context 'in admin' do
      let(:user) { nil }
      let(:admin_user) { create :admin_user }

      it 'sets distinct id to admin id' do
        helper_class.new(request, user, admin_user).analytics_track(
          label: 'test_label', data: {}
        )
        expect_analytics_events('test_label' => { 'distinct_id' => "test_clientcomm-admin_#{admin_user.id}" })
      end
    end
  end
end
