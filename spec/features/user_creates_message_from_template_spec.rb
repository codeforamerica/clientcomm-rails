require "rails_helper"

feature "templates" do
  before do
    FeatureFlag.create!(flag: 'templates', enabled: true)

    user = create :user
    client = create :client, user: user

    saved_client = Client.find_by_first_name(client.first_name)

    login_as(user, :scope => :user)
    visit client_messages_path(client)
    expect(page).to have_current_path(client_messages_path(saved_client))
  end

  scenario "user fills message send box with template", :js do
    step "clicks on template button with no templates" do
      expect(page).not_to have_content('My templates')
      page.find('.icon-insert_comment').click
      expect(page).to have_content('My templates')

      expect(page).to have_content('Make it a reusable template!')
    end

    step "user sees template in list" do
      template = create :template
      add_template(template)

      visit client_messages_path(Client.first)
      page.find('.icon-insert_comment').click

      expect(page).to have_content(template.title)
      expect(page).to have_content(template.body)
    end

    step "user adds template to main message input" do
      template = Template.first
      expect(page).to have_css '.template-popover-active'
      find('tr', text: template.title).click
      expect(find('#message_body').value).to eq template.body
    end
  end
end
