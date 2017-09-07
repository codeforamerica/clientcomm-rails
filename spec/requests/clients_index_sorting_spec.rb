require 'rails_helper'

describe 'Clients sorting order', type: :request do
  context 'GET#index' do
    it 'sorts clients with no unread messages by last_contacted_at' do
      user = create :user
      sign_in user
      clientone = create :client, user: user, last_contacted_at: 3.hours.ago, has_unread_messages: false
      clienttwo = create :client, user: user, last_contacted_at: 2.hours.ago, has_unread_messages: false
      clientthree = create :client, user: user, last_contacted_at: 1.hour.ago, has_unread_messages: false

      get clients_path
      expect(response.code).to eq '200'
      # check the sort order (clientthree, clienttwo, clientone)
      response_body = Nokogiri.parse(response.body).to_s
      expect(response_body.index(clientthree.full_name)).to be < response_body.index(clienttwo.full_name)
      expect(response_body.index(clienttwo.full_name)).to be < response_body.index(clientone.full_name)
    end

    it 'sorts clients with unread messages to top' do
      user = create :user
      sign_in user

      clientone = create :client, user: user, last_contacted_at: 15.minutes.ago, has_unread_messages: true
      clienttwo = create :client, user: user, last_contacted_at: Time.now
      clientthree = create :client, user: user, last_contacted_at: 30.minutes.ago, has_unread_messages: true

      get clients_path
      expect(response.code).to eq '200'

      # check the sort order (clientone, clientthree, clienttwo)
      response_body = Nokogiri.parse(response.body).to_s
      expect(response_body.index(clientone.full_name)).to be < response_body.index(clientthree.full_name)
      expect(response_body.index(clientthree.full_name)).to be < response_body.index(clienttwo.full_name)
    end
  end
end
