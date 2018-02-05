require 'rails_helper'

describe Retrier do
  it 'only retries on errors' do
    counter = 0

    described_class.new retries: 10, errors: [StandardError] do
      counter += 1
      raise StandardError unless counter > 3
    end

    expect(counter).to eq 4
  end

  context 'maximum retries' do
    it 'takes a custom max retry value' do
      counter = 0

      described_class.new retries: 7, errors: [StandardError] do
        counter += 1
        raise StandardError unless counter > 9
      end

      expect(counter).to eq 7
    end
  end

  context 'specifying errors' do
    class ReraiseError < StandardError; end
    class OtherReraiseError < StandardError; end
    class UnexpectedError < StandardError; end

    it 'reraises unspecified errors' do
      expect {
        described_class.new retries: 10, errors: [ReraiseError] do
          raise UnexpectedError
        end
      }.to raise_error(UnexpectedError)
    end

    it 'allows multiple errors to be specified' do
      counter = 0

      described_class.new retries: 10, errors: [ReraiseError, OtherReraiseError] do
        counter += 1
        raise ReraiseError if counter.even?
        raise OtherReraiseError if counter.odd?
      end

      expect(counter).to eq 10
    end
  end
end
