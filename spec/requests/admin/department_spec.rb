require 'rails_helper'

describe 'Department', type: :request, active_job: true do
  let(:department_name) { 'Main' }
  let(:department_phone_number) { '+14155551212' }
  let(:admin_user) { create :admin_user }

  before do
    login_as admin_user, scope: :admin_user
  end

  describe 'POST#create' do
    context 'with valid parameters' do
      it 'creates a department' do
        post admin_departments_path params: {
          name: department_name,
          phone_number: department_phone_number
        }
        expect(Department.all.count).to eq(1)
      end
    end
  end
end
