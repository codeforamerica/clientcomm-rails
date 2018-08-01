require 'rails_helper'

describe AnalyticsService do
  describe '#track' do
    let(:actor) { create :user }
    let(:distinct_id) { 'zak_clientcomm-10' }
    let(:label) { 'clicked_thing' }
    let(:base_url) { 'https://zak.clientcomm.com' }

    before do
      @deploy_base_url = ENV['DEPLOY_BASE_URL']
      ENV['DEPLOY_BASE_URL'] = base_url
    end

    after do
      ENV['DEPLOY_BASE_URL'] = @deploy_base_url
    end

    subject { described_class.track(distinct_id: distinct_id, label: label) }

    it 'sends an event to mixpanel with a local' do
      expect(MIXPANEL_TRACKER).to receive(:track)
        .with(distinct_id, label, locale: :en)
      subject
    end

    context 'the actor is an admin user' do
      let(:actor) { create :user }
      let(:distinct_id) { "zak_clientcomm-admin-#{actor.id}" }

      it 'sends an event to mixpanel with a local' do
        expect(MIXPANEL_TRACKER).to receive(:track)
          .with(distinct_id, label, locale: :en)
        subject
      end
    end

    context 'the actor is an unauthenticated visitor' do
      let(:actor) { 'session-id' }
      let(:distinct_id) { 'zak_clientcomm-session-id' }

      it 'assumes the actor is a session id' do
        expect(MIXPANEL_TRACKER).to receive(:track)
          .with(distinct_id, label, locale: :en)
        subject
      end
    end

    context 'MIXPANEL_TRACKER is not present' do
      before do
        allow(MIXPANEL_TRACKER).to receive(:present?)
          .and_return(false)
      end

      it 'does nothing' do
        expect(MIXPANEL_TRACKER).to_not receive(:track)
        subject
      end
    end

    context 'mixpanel tracking throws an error' do
      before do
        allow(MIXPANEL_TRACKER).to receive(:track).and_raise('YO')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error)
        subject
      end
    end

    context 'user agent is present' do
      let(:user_agent) { 'some user agent' }
      let(:client) do
        double(
          'client',
          bot_name: 'bot_name',
          full_version: '1.2.3',
          bot?: false,
          name: 'Zakzilla',
          device_brand: 'Zaktronix',
          device_name: 'zPhone',
          device_type: 'Cool Phone',
          os_full_version: '9.8.7',
          os_name: 'Zak OS X'
        )
      end

      before do
        allow(DeviceDetector).to receive(:new)
          .with(user_agent)
          .and_return(client)
      end

      subject do
        described_class.track(
          distinct_id: distinct_id,
          label: label,
          user_agent: user_agent
        )
      end

      it 'tracks user_agent info' do
        expect(MIXPANEL_TRACKER).to receive(:track)
          .with(
            distinct_id,
            label,
            locale: :en,
            client_bot_name: 'bot_name',
            client_full_version: '1.2.3',
            client_major_version: '1',
            client_is_bot: false,
            client_name: 'Zakzilla',
            client_device_brand: 'Zaktronix',
            client_device_name: 'zPhone',
            client_device_type: 'Cool Phone',
            client_os_full_version: '9.8.7',
            client_os_major_version: '9',
            client_os_name: 'Zak OS X'
          )
        subject
      end
    end
  end

  describe '#alias' do
    subject { AnalyticsService.alias('internal', 'visitor') }
    it 'calls alias on mixpanel' do
      expect(MIXPANEL_TRACKER).to receive(:alias).with('internal', 'visitor')
      subject
    end
  end
end
