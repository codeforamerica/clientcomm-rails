require 'rails_helper'

RSpec.describe MassMessage, type: :model do
  it {
    should validate_presence_of :message
    should validate_presence_of :clients
  }
end
