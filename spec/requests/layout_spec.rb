require 'rails_helper'

describe 'layout logic', type: :request do
  context 'authenticated' do
    before do
      sign_in user
    end

    describe 'clients#index' do
      let(:user) { create(:user) }

      it 'displays the full name' do
        get clients_path

        expect(response.body).to include(user.full_name)
      end
    end
  end
end
