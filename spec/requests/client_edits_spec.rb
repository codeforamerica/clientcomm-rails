require 'rails_helper'

RSpec.describe "ClientEdits", type: :request do
  describe "edit client form" do

    it "re-renders form if invalid data" do
      # This doesn't appear to be creating a mock client
      @client = create_client build(:client)
      get edit_client_path(id: @client.id)
      assert_template 'clients/edit'
      patch client_path(id: @client.id), params: { client: { first_name: "",
                                                      last_name: "",
                                                      birth_date: "",
                                                      phone_number: "", } }
      assert_template 'clients/edit'
    end
  end
end
