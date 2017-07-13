require "rails_helper"

let(:valid_scheduled_message) {'You have an appointment tomorrow at 10am'}

describe DatetimeHelper do
  describe "#date_or_false" do
    it "returns Time.now if no date params are present" do

    end

    it "returns an error object if the date is in the past" do

    end

    it "returns a datetime object if the date is in the future" do

    end
  end
end
