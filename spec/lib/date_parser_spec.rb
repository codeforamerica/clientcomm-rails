require 'rails_helper'

describe DateParser do
  subject {described_class.parse(date, time)}

  context 'with invalid year' do
    let(:date) {'12/03/'}
    let(:time) {'9:30pm'}

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'with two digit year' do
    let(:date) {'12/03/02'}
    let(:time) {'9:30pm'}

    it 'returns nil' do
      expect(subject).to be_nil
    end
  end

  context 'with valid date and time and one digit hour' do
    let(:date) {'12/03/2002'}
    let(:time) {'9:30pm'}

    it 'returns valid date' do
      expect(subject).to eq Time.zone.local(2002, 12, 03, 21, 30)
    end
  end

  context 'with valid date and time and two digit hour' do
    let(:date) {'12/03/2002'}
    let(:time) {'12:30pm'}

    it 'returns valid date' do
      expect(subject).to eq Time.zone.local(2002, 12, 03, 12, 30)
    end
  end

  context 'with valid date and nil time' do
    let(:date) {'12/03/2002'}
    let(:time) { nil }

    it 'returns valid date' do
      expect(subject).to eq nil
    end
  end

  context 'with valid time and nil date' do
    let(:date) { nil }
    let(:time) { '3:30pm' }

    it 'returns valid date' do
      expect(subject).to eq nil
    end
  end
end
