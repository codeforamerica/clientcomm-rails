require 'rails_helper'

describe 'User', type: :request, active_job: true do
  let(:admin_user) { create :admin_user }
  let(:department) { create :department }
  let(:user) { create :user, department: department }
  let!(:client1) { create :client, user: user, active: true }
  let!(:client2) { create :client, user: user, active: false }

  before do
    login_as admin_user, scope: :admin_user
  end

  describe '#disable' do
    it 'shows all currently active reporting relationships' do
      get disable_admin_user_path(user)

      expect(response.body).to include(client1.full_name)
      expect(response.body).not_to include(client2.full_name)
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
