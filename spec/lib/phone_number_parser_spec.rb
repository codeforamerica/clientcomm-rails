require 'rails_helper'

describe PhoneNumberParser do

  describe '#make_bare' do
    subject { described_class.make_bare(input) }

    context 'strips non-numeric characters from input' do
      let(:input) { '(243) 555-1212' }
      it { expect(subject).to eq '2435551212' }
    end

    context 'crops characters from left of too-long numbers' do
      let(:input) { '12435551212' }
      it { expect(subject).to eq '2435551212' }
    end

    context 'leaves too-short numbers unaltered' do
      let(:input) { '5551212' }
      it { expect(subject).to eq '5551212' }
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

    context 'tries to format too-short numbers' do
      let(:input) { '5551212' }
      it { expect(subject).to eq '(555) 121-2' }
    end
  end

end
