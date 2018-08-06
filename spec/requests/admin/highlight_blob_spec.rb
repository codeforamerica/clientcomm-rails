require 'rails_helper'

describe 'set highlight blob', type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  let(:admin_user) { create :user, admin: true }

  before do
    login_as admin_user
  end

  describe 'GET#new' do
    before { get new_admin_highlight_blob_path }

    it 'renders the correct form' do
      expect(response.body).to include 'Text'
    end
  end

  describe 'POST#create' do
    subject do
      post admin_highlight_blobs_path, params: {
        highlight_blob: {
          text: '<p class="test">hi, how are you</p>'
        }
      }
    end

    it 'creates a Highlight Blob with the text' do
      subject

      expect(HighlightBlob.last.text).to eq '<p class="test">hi, how are you</p>'
    end

    context 'when a disallowed tag is present' do
      subject do
        post admin_highlight_blobs_path, params: {
          highlight_blob: {
            text: '<p>hi, how are you</p><script>ignore me, in ur computerz hacking your codez</script>'
          }
        }
      end

      it 'scrubs the tags and leaves the good' do
        subject

        expect(HighlightBlob.last.text).to eq '<p>hi, how are you</p>'
      end
    end
  end
end
