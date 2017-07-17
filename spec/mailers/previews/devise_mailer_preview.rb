class DeviseMailerPreview < ActionMailer::Preview
  def invitation_instructions
    Devise::Mailer.invitation_instructions(User.first, 'some_token')
  end
end
