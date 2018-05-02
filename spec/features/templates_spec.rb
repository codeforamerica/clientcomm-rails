require 'rails_helper'

feature 'logged-out user visits create template page' do
  scenario 'and is redirected to the login form' do
    visit new_template_path
    expect(page).to have_text 'Log in'
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature 'User creates template' do
  before do
    myuser = create :user
    login_as(myuser, scope: :user)
    visit templates_path
    click_on 'New template'
    expect(page).to have_current_path(new_template_path)
  end

  scenario 'successfully', :js do
    template = build :template, title: 'My template title', body: 'My template body'

    add_template(template)

    expect(page).to have_current_path(templates_path)
    expect(page).to have_content 'My template title'
    expect(page).to have_content 'My template body'
  end

  scenario 'unsuccessfully' do
    template = build :template, title: nil, body: 'Some text'

    add_template(template)

    expect(page).to have_content 'New template'
    expect(page).to have_content 'Give your template a name so you can find it in the list.'
  end
end

feature 'User edits template' do
  before do
    myuser = create :user
    login_as(myuser, scope: :user)
    visit templates_path
  end

  scenario 'successfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by(title: template.title)))

    fill_in 'Template name', with: 'New template title'
    fill_in 'Template', with: 'New template body'
    click_on 'Update'

    expect(page).to have_current_path(templates_path)
    expect(page).to have_content 'New template title'
    expect(page).to have_content 'New template body'
  end

  scenario 'unsuccessfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by(title: template.title)))

    fill_in 'Template name', with: ''
    fill_in 'Template', with: ''
    click_on 'Update'

    expect(page).to have_content 'Give your template a name so you can find it in the list.'
    expect(page).to have_content 'Add a template.'
  end
end

feature 'User deletes template' do
  before do
    myuser = create :user
    login_as(myuser, scope: :user)
    visit templates_path
  end

  scenario 'successfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by(title: template.title)))

    accept_confirm do
      click_on 'Delete template'
    end

    expect(page).to have_current_path(templates_path)
    expect(page).to have_content 'Template deleted'
  end
end

feature 'templates' do
  let(:user) { create :user }
  let(:client) { create :client, user: user }

  before do
    FeatureFlag.create!(flag: 'templates', enabled: true)

    login_as(user, scope: :user)
    rr = user.reporting_relationships.find_by(client: client)
    visit reporting_relationship_path(rr)
  end

  scenario 'user fills message send box with template', :js do
    step 'clicks on template button with no templates' do
      expect(page).not_to have_content('My templates')
      page.find('.icon-insert_comment').click
      expect(page).to have_content('My templates')

      expect(page).to have_content('Make it a reusable template!')
    end

    step 'user sees template in list' do
      template = create :template
      add_template(template)

      rr = user.reporting_relationships.find_by(client: client)
      visit reporting_relationship_path(rr)
      page.find('.icon-insert_comment').click

      expect(page).to have_content(template.title)
      expect(page).to have_content(template.body)
    end

    step 'user adds template to main message input' do
      template = Template.first
      expect(page).to have_css '.template-popover-active'
      find('tr', text: template.title).click
      expect(find('#message_body').value).to eq template.body
    end
  end
end
