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
        phone_number: client.phone_number,
        'birth_date(1i)': client.birth_date.year,
        'birth_date(2i)': client.birth_date.month,
        'birth_date(3i)': client.birth_date.day
      }
    }
    post clients_path, params: post_params
    # return the saved client record
    Client.find_by(phone_number: client.phone_number)
  end

  def create_message(message)
    post_params = {
      message: { body: message.body },
      client_id: message.client.id
    }
    post messages_path, params: post_params
    # return the saved message record
    # NOTE: send unique body text to ensure the correct message is returned
    Message.find_by(body: message.body)
  end

end
