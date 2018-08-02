require 'rails_helper'

describe 'User', type: :request, active_job: true do
  let(:admin_user) { create :user, admin: true }
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let!(:client1) { create :client, first_name: 'test', last_name: 'user', user: user, active: true }

  before do
    login_as admin_user
  end

  describe '#create' do
    let(:user_full_name) { 'Carlton Lassiter' }
    let(:user_email) { 'classiter@sbpd.gov' }
    let(:user_password) { 'thisismypassword' }
    let(:user_params) do
      {
        full_name: user_full_name,
        email: user_email,
        password: user_password,
        password_confirmation: user_password
      }
    end

    subject do
      post admin_users_path, params: {
        user: user_params
      }
    end

    it 'creates a new user' do
      subject

      new_user = User.last
      expect(new_user.full_name).to eq(user_full_name)
      expect(new_user.email).to eq(user_email)
    end

    context 'other params' do
      let(:user_params) do
        {
          full_name: user_full_name,
          email: user_email,
          password: user_password,
          password_confirmation: user_password,
          message_notification_emails: false,
          treatment_group: 'ebp-liking-cats',
          admin: true
        }
      end

      it 'sets the relevant flags' do
        subject

        new_user = User.last
        expect(new_user.message_notification_emails).to eq(false)
        expect(new_user.treatment_group).to eq('ebp-liking-cats')
        expect(new_user.admin).to eq(true)
      end
    end
  end

  describe '#disable' do
    it 'shows all currently active reporting relationships' do
      get disable_admin_user_path(user)

      expect(response.body).to include(client1.full_name)
    end
  end

  describe '#disable_confirm' do
    it 'should disable all associated reporting relationships' do
      expect do
        get disable_confirm_admin_user_path(user)
      end.to change { user.reporting_relationships.active.count }.from(1).to(0)
    end

    it 'should disable the user' do
      expect do
        get disable_confirm_admin_user_path(user)
      end.to change { user.reload.active }.from(true).to(false)
    end
  end
end
