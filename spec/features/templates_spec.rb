require "rails_helper"

feature "logged-out user visits create template page" do
  scenario "and is redirected to the login form" do
    visit new_template_path
    expect(page).to have_text "Log in"
    expect(page).to have_current_path(new_user_session_path)
  end
end

feature "User creates template" do
  before do
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit templates_path
    click_on 'New template'
    expect(page).to have_current_path(new_template_path)
  end

  scenario 'successfully', :js do
    expect(page).to have_content 'Make a template!'

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
    expect(page).to have_content "Template name can't be blank"
  end
end

feature "User edits template" do
  before do
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit templates_path
  end

  scenario 'successfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by_title(template.title)))

    fill_in "Template name", with: 'New template title'
    fill_in "Template", with: 'New template body'
    click_on "Update"

    expect(page).to have_current_path(templates_path)
    expect(page).to have_content 'New template title'
    expect(page).to have_content 'New template body'

  end

  scenario 'unsuccessfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by_title(template.title)))

    fill_in "Template name", with: 'New template title'
    fill_in "Template", with: ''
    click_on "Update"

    expect(page).to have_content "can't be blank"
  end
end

feature "User deletes template" do
  before do
    myuser = create :user
    login_as(myuser, :scope => :user)
    visit templates_path
  end

  scenario 'successfully', :js do
    template = build :template, title: 'Edit this template title', body: 'Edit this template body'
    add_template(template)

    find('a .icon-mode_edit').click

    expect(page).to have_current_path(edit_template_path(Template.find_by_title(template.title)))

    accept_confirm do
      click_on "Delete template"
    end

    expect(page).to have_current_path(templates_path)
    expect(page).to have_content "Template deleted"
  end
end
