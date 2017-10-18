require 'rails_helper'

describe 'Layouts', type: :request do
  describe 'Navigation bar' do

    context 'help link' do
      let(:help_link) { 'help me omg' }

      before do
        @help_link = ENV['HELP_LINK']
        ENV['HELP_LINK'] = help_link

        sign_in create :user
      end

      after { ENV['HELP_LINK'] = @help_link }

      subject { get root_path }

      it 'displays a help link' do
        subject

        expect(response.body).to include 'Help'
      end

      context 'there is no help link set' do
        let(:help_link) { nil }

        it 'does not display a help link' do
          subject

          expect(response.body).to_not include 'Help'
        end
      end
    end
  end
end
