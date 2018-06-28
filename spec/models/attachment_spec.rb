require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'validations' do
    it { should belong_to :message }
    it {
      should validate_attachment_content_type(:media)
        .allowing('text/vcard')
        .rejecting('png/whatever')
    }
    it 'extracts dimensions' do
      attachment = create :attachment
      attachment.reload
      expect(attachment.dimensions).to eq([3024, 3024])
    end
  end

  describe '#image?' do
    let(:attachment) {
      create :attachment, media: File.new(media_path)
    }
    subject { attachment.image? }

    context 'image' do
      let(:media_path) { Rails.root.join('spec', 'fixtures', 'fluffy_cat.jpg') }

      it 'returns true' do
        expect(subject).to eq true
      end
    end

    context 'not an image' do
      let(:media_path) { Rails.root.join('spec', 'fixtures', 'cat_contact.vcf') }

      it 'returns true' do
        expect(subject).to eq false
      end
    end
  end
end
