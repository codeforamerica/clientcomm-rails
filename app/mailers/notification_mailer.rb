class NotificationMailer < ApplicationMailer
  helper ApplicationHelper
  class NoPhoneNumberOrNameChangeError < ArgumentError; end

  rescue_from NoPhoneNumberOrNameChangeError do |exception|
    Rails.logger.warn exception.message
  end

  def court_reminders_success(user)
    @reminders_scheduled = CourtReminder.scheduled.count
    mail(
      to: user.email,
      subject: 'Your recent ClientComm upload - success!'
    )
  end

  def court_reminders_failure(user)
    mail(
      to: user.email,
      subject: 'Error with your recent ClientComm upload'
    )
  end

  def message_notification(user, message)
    @client = message.client
    @message = message
    FileUtils.mkdir_p(Rails.root.join('tmp', 'attachments'))
    @message.attachments.each do |a|
      tmp_path = Rails.root.join('tmp', 'attachments', SecureRandom.urlsafe_base64)
      a.media.copy_to_local_file(:original, tmp_path)
      file = File.read(tmp_path)
      attachments[a.media_file_name] = file
    end

    mail(
      to: user.email,
      subject: "New text message from #{@client.first_name} #{@client.last_name} on ClientComm"
    )
  end

  def client_transfer_notification(current_user:, previous_user:, client:, transfer_note: nil, transferred_by: nil)
    @current_user = current_user
    @previous_user = previous_user
    @client = client
    @transfer_note = transfer_note
    @transferred_by = transferred_by

    mail(
      to: @current_user.email,
      subject: 'You have a new client on ClientComm'
    )
  end

  def report_usage(recipient, metrics, end_date)
    @end_date = Time.zone.parse(end_date)
    @start_date = @end_date - 7.days
    @metrics = metrics
    @total_outbound = 0
    @total_scheduled = 0
    @total_inbound = 0
    @total_total = 0
    csv_str = CSV.generate headers: true do |csv|
      csv << %w[Name Outbound Scheduled Inbound Total]

      metrics.each do |metric|
        csv << metric
        @total_outbound += metric[1].to_i
        @total_scheduled += metric[2].to_i
        @total_inbound += metric[3].to_i
        @total_total += metric[4].to_i
      end
    end

    attachments["metrics-#{@end_date.strftime('%-m-%-d-%Y')}.csv"] = csv_str

    mail(
      to: recipient,
      subject: I18n.t('report_mailer.subject', start_date: @start_date.strftime('%-m/%-d/%y'), end_date: @end_date.strftime('%-m/%-d/%y'))
    )
  end

  def client_edit_notification(notified_user:, editing_user:, client:, previous_changes:)
    if previous_changes['first_name'].present? || previous_changes['last_name'].present?
      first_name = previous_changes.dig('first_name', 0) || client.first_name
      last_name = previous_changes.dig('last_name', 0) || client.last_name
      @full_name = "#{first_name} #{last_name}"
    end
    @phone_number = previous_changes['phone_number'].try(:[], 0)

    raise NoPhoneNumberOrNameChangeError, 'Phone number and name did not change.' if @phone_number.nil? && @full_name.nil?

    @notified_user = notified_user
    @editing_user = editing_user
    @client = client

    mail(
      to: @notified_user.email,
      subject: "Your client's contact information has been updated"
    )
  end

  def batch_transfer_notification(current_user:, transferred_clients:)
    @current_user = current_user
    @transferred_clients = transferred_clients

    mail(
      to: @current_user.email,
      subject: "You have #{@transferred_clients.count} new clients on ClientComm"
    )
  end
end
