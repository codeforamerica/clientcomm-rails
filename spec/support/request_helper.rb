module RequestHelper
  def sign_in(user)
    post_params = { user: { email: user.email, password: user.password } }
    post user_session_path, params: post_params
  end

  def create_client(client)
    post_params = {
      client: {
        first_name: client.first_name,
        last_name: client.last_name,
        phone_number: client.phone_number
      }
    }
    post clients_path, params: post_params
    # return the saved client record
    # NOTE: send a unique phone number to ensure the correct client is returned
    Client.find_by(phone_number: client.phone_number)
  end

  def edit_client(client_id, client)
    patch_params = {
      client: {
        first_name: client.first_name,
        last_name: client.last_name,
        phone_number: client.phone_number
      }
    }
    patch client_path(client_id), params: patch_params
    # return the edited client record
    Client.find(client_id)
  end
end
