require 'rails_helper'

describe 'User requests', type: :request do
  let(:user) { create :user, password: 'password-one' }

  context 'unauthenticated' do
    it 'rejects edits when user unauthenticated' do
      get edit_user_registration_path(user)
      expect(response.code).to eq '401'
    end
  end

  context 'authenticated' do
    before do
      sign_in user
    end

    describe 'GET#show' do
      it 'shows user profile' do
        get edit_user_registration_path
        expect(response.code).to eq '200'
      end
    end

    describe 'PUT#udpate' do
      context "update account information" do
        let(:new_name) { Faker::Name.name }
        let(:new_email) { Faker::Internet.unique.email }
        let(:new_desk_phone) { '(466) 336-4863' }

        before do
          patch user_registration_path, params: {
            user: {
              full_name: new_name,
              email: new_email,
              desk_phone_number: new_desk_phone
            },
            update_settings: ""
          }
        end

        it 'updates user account information' do
          expect(response.code).to eq '302'
          expect(response).to redirect_to(edit_user_registration_path)
          expect(user.reload.full_name).to eq new_name
        end
      end

      context "successfully" do
        let(:password) { 'newpassword' }

        before do
          patch user_registration_path, params: {
            user: {
              current_password: user.password,
              password: password,
              password_confirmation: password
            },
            change_password: ""
          }
        end

        it 'updates password' do
          expect(response.code).to eq '302'
        end
      end

      context "unsuccessfuly" do
        let(:password) { 'newpassword' }

        before do
          patch user_registration_path, params: {
            user: {
              current_password: 'badpassword',
              password: 'worsepassword',
              password_confirmation: 'worstpassword'
            },
            change_password: ""
          }
        end

        it 'fails to update password' do
          expect(response.code).to eq '200'
          expect(response.body).to include 'is invalid'
          expect(response.body).to include "doesn't match Password"
        end
      end
    end
  end

end
