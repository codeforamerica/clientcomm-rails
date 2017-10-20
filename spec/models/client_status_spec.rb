require 'rails_helper'

RSpec.describe ClientStatus, type: :model do
  it { should validate_presence_of :followup_date }
  it { should validate_presence_of :name }
end
