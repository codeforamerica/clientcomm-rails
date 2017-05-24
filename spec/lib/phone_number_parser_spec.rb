require 'rails_helper'

describe PhoneNumberParser do

  describe '#normalize' do
    subject { described_class.normalize(input) }

    context 'adds country code to a bare number' do
      let(:input) { '2435551212' }
      it { expect(subject).to eq '+12435551212' }
    end

    context 'normalizes a number with non-numeric characters' do
      let(:input) { '(243) 555-1212' }
      it { expect(subject).to eq '+12435551212' }
    end
  end

  describe '#format_for_display' do
    subject { described_class.format_for_display(input) }

    context 'formats a normalized number for display' do
      let(:input) { '+12435551212' }
      it { expect(subject).to eq '(243) 555-1212' }
    end

    context 'formats a bare number for display' do
      let(:input) { '2435551212' }
      it { expect(subject).to eq '(243) 555-1212' }
    end
  end

end
