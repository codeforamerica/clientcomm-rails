require 'rails_helper'

describe 'Department', type: :request, active_job: true do
  let(:department_name) { 'Main' }
  let(:department_phone_number) { '+14155551212' }
  let(:admin_user) { create :user, admin: true }

  before do
    login_as admin_user
  end

  describe 'POST#create' do
    context 'with valid parameters' do
      it 'creates a department' do
        post admin_departments_path params: {
          department: {
            name: department_name,
            phone_number: department_phone_number
          }
        }

        new_department = Department.last
        expect(new_department.phone_number).to eq(department_phone_number)
        expect(new_department.name).to eq(department_name)
      end
    end
  end
end
