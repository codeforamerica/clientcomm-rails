require "rails_helper"

feature "User clicks on client in list", :js do

  describe "and sees the messages page" do
    let!(:myuser) { create :user }
    let!(:myclient) { create :client, user: myuser }

    context "on the client list page" do
      before do
        login_as(myuser, :scope => :user)
        visit clients_path
      end

      it "shows client name in table list" do
        expect(page).to have_css '.data-table td', text: myclient.full_name
      end

      it "has the correct path" do
        expect(page).to have_current_path(clients_path)
      end

      it "clicking on the client leads to client messages path" do
        find('td', text: myclient.full_name).click
        expect(page).to have_current_path(client_messages_path(myclient))
      end
    end

    context "on the messages page" do

      before do
        login_as(myuser, :scope => :user)
        visit client_messages_path(myclient)
      end

      it "shows the client's name in the header" do
        expect(page).to have_content myclient.full_name
      end

      it "shows the client's phone number in the header" do
        expect(page).to have_content PhoneNumberParser.format_for_display(myclient.phone_number)
      end

      it "shows the client's notes in the header" do
        expect(page).to have_content myclient.notes
      end
      # get the id from the saved client record
      it "has the correct path for the client" do
        myclient_id = Client.find_by(phone_number: PhoneNumberParser.normalize(myclient.phone_number)).id
        expect(page).to have_current_path(client_messages_path(client_id: myclient_id))
      end
    end

  end
end

feature "User sees client notes on messages page", :js do
  context "visits clients page on mobile" do
    let!(:myuser) { create :user }
    let!(:myclient) { create :client, user: myuser }

    before do
      resize_window_to_mobile
    end

    after do
      resize_window_default
    end

    it "hides notes on mobile" do
      login_as(myuser, :scope => :user)
      visit client_messages_path(myclient)
      expect(page).to_not have_content myclient.notes
    end
  end
end
