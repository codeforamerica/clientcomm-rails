module NotificationSender
  def self.notify_users_of_changes(user:, client:)
    create_edit_markers_for_phone_number_change(user: user, client: client)
    notify_shared_users_of_changes(user: user, client: client)
  end

  def self.create_edit_markers_for_phone_number_change(user:, client:)
    return unless client.phone_number_previously_changed?

    Message.create_client_edit_markers(
      user: user,
      phone_number: client.phone_number,
      reporting_relationships: client.reporting_relationships.active,
      as_admin: false
    )
  end

  def self.notify_shared_users_of_changes(user:, client:)
    other_active_relationships = client.reporting_relationships.active.where.not(user: user)

    other_active_relationships.each do |rr|
      NotificationMailer.client_edit_notification(
        notified_user: rr.user,
        editing_user: user,
        client: client,
        previous_changes: client.previous_changes.except(:updated_at, :next_court_date_at)
      ).deliver_later
    end
  end
end
