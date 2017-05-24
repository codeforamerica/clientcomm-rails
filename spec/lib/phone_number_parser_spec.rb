require "rails_helper"

describe PhoneNumberParser do
  it "adds country code to a bare number" do
    input_number = "2435551212"
    expect(described_class.normalize(input_number)).to eq "+12435551212"
  end

  it "normalizes a number with non-numeric characters" do
    input_number = "(243) 555-1212"
    expect(described_class.normalize(input_number)).to eq "+12435551212"
  end

  it "formats a normalized number for display" do
    input_number = "+12435551212"
    expect(described_class.format_for_display(input_number)).to eq "(243) 555-1212"
  end

  it "formats a bare number for display" do
    input_number = "2435551212"
    expect(described_class.format_for_display(input_number)).to eq "(243) 555-1212"
  end
end
