require 'rails_helper'

describe Department, type: :model do
  it { should have_many :users }
  it { should belong_to :unclaimed_user }

  describe 'validations' do
    it 'validates correctness of phone_number' do
      bad_number = '(212) 55-5236'
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: bad_number)
        .and_raise(SMSService::NumberNotFound)

      new_dept = build(:department, phone_number: bad_number)
      expect(new_dept.valid?).to eq(false)
      expect(new_dept.errors.keys).to contain_exactly(:phone_number)
    end

    it 'does not validate correctness of phone_number if phone number unchanged' do
      dept = create :department
      expect(SMSService.instance).not_to receive(:number_lookup)
      dept.update!(name: 'some other name')
    end
  end

  describe 'normalizing' do
    let(:input_phone_number) { '(760) 555-7890' }
    let(:normalized_phone_number) { '+17605557890' }
    before do
      allow(SMSService.instance).to receive(:number_lookup)
        .with(phone_number: input_phone_number)
        .and_return(normalized_phone_number)
    end

    subject { create :department, phone_number: input_phone_number }

    it 'formats the phone number' do
      expect(subject.reload.phone_number).to eq(normalized_phone_number)
    end
  end
end
