class CourtReminderMailer < ApplicationMailer
  helper ApplicationHelper

  def success(user)
    @reminders_scheduled = CourtReminders.all.count
    mail(
      to: user.email,
      subject: "#{@reminders_scheduled} court reminders were scheduled on ClientComm"
    )
  end
end
