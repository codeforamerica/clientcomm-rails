module RequestHelper
  def sign_in(user)
    post_params = { user: { email: user.email, password: user.password } }
    post user_session_path, params: post_params
  end

  def create_user(user)
    post_params = {
      user: {
        full_name: user.full_name,
        email: user.email,
        password: user.password,
        password_confirmation: user.password
      }
    }
    post user_registration_path, params: post_params
    # return the saved user record
    # NOTE: send a unique email to ensure the correct user is returned
    User.find_by(email: user.email)
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

  def create_message(message)
    post_params = {
      message: { body: message.body },
      client_id: message.client.id
    }

    if message.send_at
      post_params[:message] = post_params[:message].merge({
        'send_at(1i)': message.send_at.year,
        'send_at(2i)': message.send_at.month,
        'send_at(3i)': message.send_at.day,
        'send_at(4i)': message.send_at.hour,
        'send_at(5i)': message.send_at.min
      })
    end

    post messages_path, params: post_params
    # return the saved message record
    # NOTE: send unique body text to ensure the correct message is returned
    Message.find_by(body: message.body)
  end
end
