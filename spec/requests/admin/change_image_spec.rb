require 'rails_helper'

describe 'upload change image', type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  let(:admin_user) { create :user, admin: true }

  before do
    login_as admin_user
  end

  describe 'GET#new' do
    before { get new_admin_change_image_path }

    it 'renders the correct form' do
      expect(response.body).to include 'Upload image'
    end
  end

  describe 'POST#create' do
    let(:department) { create :department }
    subject do
      file = fixture_file_upload('fluffy_cat.jpg', 'image/jpeg')
      post admin_change_images_path, params: {
        change_image: {
          file: file
        }
      }
    end

    it 'creates a change image object with the correct file' do
      subject

      expect(ChangeImage.last.file_content_type).to eq 'image/jpeg'
      expect(ChangeImage.last.file_file_name).to eq 'fluffy_cat.jpg'
    end

    it 'redirects to the listing page' do
      subject
      expect(response).to redirect_to(admin_change_images_path)
    end
  end

  describe 'GET#show' do
    let(:filename) { 'fluffy_cat.jpg' }
    let(:change_image) { ChangeImage.create!(file: File.new("./spec/fixtures/#{filename}"), user: admin_user) }
    before { get admin_change_image_path change_image }

    it 'renders the show page with a download link' do
      page = Nokogiri.parse(response.body)

      expect(page.css('div.panel h3').text).to eq 'Change Image Details'
      expect(page.css('tr.row-file_file_name a').attr('href').text).to eq download_admin_change_image_path(change_image)
    end
  end
end
