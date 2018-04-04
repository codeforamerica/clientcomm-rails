require 'rails_helper'

describe 'Help requests', type: :request do
  context 'unauthenticated' do
    let(:help_link) { 'help me omg' }

    before do
      @help_link = ENV['HELP_LINK']
      ENV['HELP_LINK'] = help_link
    end

    after { ENV['HELP_LINK'] = @help_link }

    subject { get help_index_path }

    it 'redirects the user to the github help page' do
      subject
      expect_analytics_events_happened('help_page_click')
      expect(response).to redirect_to help_link
    end

    context 'no help page is set' do
      let(:help_link) { '' }

      it 'raises a 404 error' do
        expect { subject }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
