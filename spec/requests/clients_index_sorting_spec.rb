require 'rails_helper'

describe 'Clients sorting order', type: :request do
  context 'GET#index' do
    it 'sorts clients with no messages by updated_at' do
      user = create :user
      sign_in user
      clientone = nil
      clienttwo = nil
      clientthree = nil
      travel_to 3.hours.ago do
        clientone = create :client, user: user
      end
      travel_to 2.hours.ago do
        clienttwo = create :client, user: user
      end
      travel_to 1.hours.ago do
        clientthree = create :client, user: user
      end
      get clients_path
      expect(response.code).to eq '200'
      # check the sort order (clientthree, clienttwo, clientone)
      expect(response.body.index(clientthree.full_name)).to be < response.body.index(clienttwo.full_name)
      expect(response.body.index(clienttwo.full_name)).to be < response.body.index(clientone.full_name)
    end

    it 'sorts clients with unread messages to top' do
      user = create :user
      sign_in user
      clientone = nil
      clienttwo = nil
      clientthree = nil
      travel_to 3.hours.ago do
        clientone = create :client, user: user
      end
      travel_to 2.hours.ago do
        clienttwo = create :client, user: user
      end
      travel_to 1.hours.ago do
        clientthree = create :client, user: user
      end

      # receive a message from clientthree 30 minutes ago
      travel_to 30.minutes.ago do
        create :message, user: user, client: clientthree, inbound: true, read: false
      end
      # receive a message from clientone 15 minutes ago
      travel_to 15.minutes.ago do
        create :message, user: user, client: clientone, inbound: true, read: false
      end
      # send a message to clienttwo now
      create :message, user: user, client: clienttwo, inbound: false, read: true
      get clients_path
      expect(response.code).to eq '200'
      # check the sort order (clientone, clientthree, clienttwo)
      expect(response.body.index(clientone.full_name)).to be < response.body.index(clientthree.full_name)
      expect(response.body.index(clientthree.full_name)).to be < response.body.index(clienttwo.full_name)
    end
  end
end
