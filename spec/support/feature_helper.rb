module FeatureHelper
  def login(the_user)
    visit new_user_session_path
    fill_in 'Email', with: the_user.email
    fill_in 'Password', with: the_user.password
    click_on 'Sign in'
    expect(page).to have_text 'My clients'
    expect(page).to have_current_path(root_path)
  end

  def add_client(the_client)
    visit new_client_path
    fill_in 'First name', with: the_client.first_name
    fill_in 'Last name', with: the_client.last_name
    fill_in 'Phone number', with: the_client.phone_number
    fill_in 'Notes', with: the_client['notes']
    click_on 'Save new client'
    expect(page).to have_content('Manage client')
  end

  def add_template(the_template)
    visit new_template_path
    fill_in 'Template name', with: the_template.title
    fill_in 'Template', with: the_template.body
    click_on 'Save template'
    expect(page).to have_current_path(templates_path)
  end

  def wait_for(reason, timeout: Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      loop do
        return_value = yield
        break return_value if return_value
        sleep 0.1
      end
    end
  rescue Timeout::Error
    fail "Timed out waiting for #{reason}"
  end

  def xstep(title)
    puts "PENDING STEP SKIPPED: #{title}" if ENV['LOUD_TESTS']
  end

  def step(title)
    puts "STEP: #{title}" if ENV['LOUD_TESTS']
    yield
  end

  def save_and_open_preview
    file_preview_url = file_preview_url(host: 'localhost:3000', file: save_page)
    `open #{file_preview_url}`
  end

  def wut
    # if you want to see CSS with this command, see file_previews_controller.rb
    save_and_open_preview
  end

  def table_contents(selector, header: true)
    [].tap do |contents|
      within(selector) do
        if header
          all('thead tr').map do |tr|
            contents << tr.all('th').map(&:text)
          end
        end
        all('tbody tr').map do |tr|
          contents << tr.all('th, td').map(&:text)
        end
      end
    end
  end

  def on_page(page_title)
    expect(page.title).to eq page_title
    puts "PAGE: #{page_title}" if ENV['LOUD_TESTS']
    # Protection against missed i18n links
    expect(page).not_to have_text('{')
    yield
  end
end
