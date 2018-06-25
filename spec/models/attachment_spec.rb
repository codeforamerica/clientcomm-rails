require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'relationships' do
    it { should belong_to :message }
  end

  describe 'paperclip content type validations' do
    it {
      should validate_attachment_content_type(:media)
        .allowing('text/vcard')
        .rejecting('png/whatever')
    }
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
