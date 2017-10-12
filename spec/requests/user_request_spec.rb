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
      context 'update account information' do
        let(:new_name) { Faker::Name.name }
        let(:new_email) { Faker::Internet.unique.email }
        let(:new_desk_phone) { '(466) 336-4863' }

        subject do
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
          subject

          expect(response.code).to eq '302'
          expect(response).to redirect_to(edit_user_registration_path)
          expect(user.reload.full_name).to eq new_name
        end

        context 'missing email' do
          let(:new_email) { '' }


          it 'fails to update settings' do
            subject
            expect(response.code).to eq '200'
            expect(response.body).to include "can't be blank"
          end
        end
      end

      context 'password changes' do
        let(:password) { 'newpassword' }
        let(:password_confirmation) { password }

        subject do
          patch user_registration_path, params: {
            user: {
              current_password: user.password,
              password: password,
              password_confirmation: password_confirmation
            },
            change_password: ""
          }
        end

        it 'updates password' do
          subject

          expect(response.code).to eq '302'
        end

        context 'with mismatched confirmation' do
          let(:password_confirmation) { password + 'bad' }

          it 'fails to update password' do
            subject

            expect(response.code).to eq '200'
            expect(response.body).to include "doesn't match Password"
          end
        end
      end
    end
  end
end
