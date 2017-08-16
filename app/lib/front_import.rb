class FrontImport
  def initialize(front_token:)
    @front_token = front_token
    @front_client = FrontClient.new(auth_token: @front_token)
  end

  def create_contact_from_id(user:, contact_id:)
    response = @front_client.contact(contact_id)
    phone_number = response['handles'][0]['handle']

    if response['name']
      split_name = response['name'].split(' ')
      if split_name.length < 2

        create_client(
            phone_number: phone_number,
            last_name: response['name'],
            user: user
        )
      else

        create_client(
            phone_number: phone_number,
            first_name: split_name[0],
            last_name: split_name[1],
            user: user
        )
      end
    else
      create_contact_from_phone_number(user: user, phone_number: phone_number)
    end
  end

  def create_contact_from_phone_number(user:, phone_number:)
    create_client(
        phone_number: phone_number,
        last_name: phone_number,
        user: user
    )
  end

  def conversations(user:, inbox_id:)
    response = @front_client.inbox_conversations(inbox_id)

    response.map do |result|
      contact = result['recipient']['_links']['related']['contact']

      if contact.nil?
        create_contact_from_phone_number(user: user, phone_number: result['recipient']['handle'])
      else
        create_contact_from_id(user: user, contact_id: contact.sub('https://api2.frontapp.com/contacts/', ''))
      end

      result['id']
    end
  end

  def inboxes
    @inboxes ||= get_inboxes
  end

  def import(email:)
    teammates = @front_client.teammates

    user = teammates.find do |teammate|
      teammate['email'] == email
    end

    user_model = User.find_or_initialize_by(email: email)
    user_model.update(full_name: "#{user['first_name']} #{user['last_name']}", password: SecureRandom.uuid)
    user_model.save!

    # get the inbox for the provided user name
    inbox_id = inboxes[user_model.full_name]

    # get all conversations
    conversation_ids = conversations(user: user_model, inbox_id: inbox_id)

    # import all messages
  end

  private

  def create_client(phone_number:, first_name: nil, last_name:, user:)
    phone_number = PhoneNumberParser.normalize(phone_number)

    return if Client.find_by_phone_number(phone_number).present?

    Client.create!(
        phone_number: phone_number,
        first_name: first_name,
        last_name: last_name,
        user: user
    )
  end

  def get_inboxes
    response = @front_client.inboxes

    inboxes = {}

    response.each do |result|
      inboxes[result['name']] = result['id']
    end

    inboxes
  end
end

class FrontClient
  FRONT_API_PATH = 'https://api2.frontapp.com'

  def initialize(auth_token:)
    @auth_token = auth_token
  end

  def inbox_conversations(inbox_id)
    list "#{FRONT_API_PATH}/inboxes/#{inbox_id}/conversations?limit=100"
  end

  def inboxes
    list "#{FRONT_API_PATH}/inboxes?limit=100"
  end

  def contact(contact_id)
    get "#{FRONT_API_PATH}/contacts/#{contact_id}?limit=100"
  end

  def teammates
    list "#{FRONT_API_PATH}/teammates?limit=100"
  end

  private

  def get(path)
    response = retryable_request { HTTParty.get(path, headers: headers) }

    if response['_error']
      ap path
      ap response
      raise StandardError
    end

    response
  end

  def list(path)
    response = get(path)
    if response['_pagination']['next']
      response['_results'].concat(list(response['_pagination']['next']))
    end
    response['_results']
  end

  def headers
    {
        'Authorization': "Bearer #{@auth_token}",
        'Accept': 'application/json'
    }
  end

  def retryable_request(&block)
    response = block.call

    raise RateLimitExceeded if response.code == 429

    response
  rescue RateLimitExceeded
    sleep_for = response.headers['retry-after'].to_i
    puts "Rate limit reached, sleeping for #{sleep_for}"
    sleep sleep_for
    retry
  end
end

class RateLimitExceeded < StandardError;
end
