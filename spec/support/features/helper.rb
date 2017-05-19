module Features
  def login(the_user)
    visit new_user_session_path
    fill_in "Email", with: the_user.email
    fill_in "Password", with: the_user.password
    click_on "Sign in"
    expect(page).to have_text "My clients"
    expect(page).to have_current_path(root_path)
  end

  def add_client(the_client)
    visit new_client_path
    fill_in "First name", with: the_client.first_name
    fill_in "Last name", with: the_client.last_name
    select Date::MONTHNAMES[the_client.birth_date.month], from: "client_birth_date_2i"
    select the_client.birth_date.day.to_s, from: "client_birth_date_3i"
    select the_client.birth_date.year.to_s, from: "client_birth_date_1i"
    fill_in "Phone number", with: the_client.phone_number
    click_on "Save new client"
    expect(page).to have_current_path(clients_path)
  end

  def xstep(title)
    puts "PENDING STEP SKIPPED: #{title}" if ENV["LOUD_TESTS"]
  end

  def step(title)
    puts "STEP: #{title}" if ENV["LOUD_TESTS"]
    yield
  end

  def save_and_open_preview
    file_preview_url = file_preview_url(host: "localhost:3000", file: save_page)
    `open #{file_preview_url}`
  end

  def wut
    save_and_open_preview
  end

  def flash
    find(".flash").text
  end

  def table_contents(selector, header: true)
    [].tap do |contents|
      within(selector) do
        if header
          all("thead tr").map do |tr|
            contents << tr.all("th").map(&:text)
          end
        end
        all("tbody tr").map do |tr|
          contents << tr.all("th, td").map(&:text)
        end
      end
    end
  end

  def on_page(page_title)
    expect(page.title).to eq page_title
    puts "PAGE: #{page_title}" if ENV["LOUD_TESTS"]
    # Protection against missed i18n links
    expect(page).not_to have_text("{")
    yield
  end
end
