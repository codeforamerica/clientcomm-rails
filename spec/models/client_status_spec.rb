require 'rails_helper'

RSpec.describe ClientStatus, type: :model do
  it { should belong_to :department }
  it { should validate_presence_of :name }
  it { should validate_presence_of :icon_color }
end
