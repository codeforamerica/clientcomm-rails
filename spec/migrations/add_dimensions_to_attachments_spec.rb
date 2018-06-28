require 'rails_helper.rb'
require_relative '../../db/migrate/20180628172800_add_dimensions_to_attachments.rb'

describe AddDimensionsToAttachments do
  let(:rr) { create :reporting_relationship, active: false }

  after do
    ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), @current_migration
    Message.reset_column_information
  end

  describe '#up' do
    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180627210514
      Message.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180628172800
      Message.reset_column_information
    end

    it 'Adds dimensions to images' do
      message = Message.create!(
        reporting_relationship_id: rr.id,
        original_reporting_relationship_id: rr.id,
        read: false,
        inbound: true,
        send_at: Time.zone.now,
        type: 'TextMessage',
        number_from: rr.client.phone_number,
        number_to: rr.user.department.phone_number
      )
      attachment = Attachment.create!(
        message: message,
        media: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'fluffy_cat.jpg'), 'image/png')
      )
      subject
      attachment.reload
      binding.pry
      expect(attachment.dimensions).to eq(['1', '1'])
    end
  end
end
