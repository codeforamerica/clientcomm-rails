require 'rails_helper'

describe 'layout logic', type: :request do
  context 'authenticated' do
    before do
      sign_in user
    end

    describe 'clients#index' do
      context 'user has full name' do
        let(:user) { create(:user, full_name: 'some name') }

        it 'displays the full name' do
          get clients_path

          expect(response.body).to include(user.full_name)
        end
      end

      context 'user does not have full name' do
        let(:user) { create(:user, full_name: '') }

        it 'displays user email address' do
          get clients_path

          expect(response.body).to include(user.email)
        end
      end
    end
  end
end
