module ClientStatusHelper
  def relationships_with_statuses_due_for_follow_up(user:)
    output = {}

    ClientStatus.where.not(followup_date: nil).map do |status|
      followup_date = Time.now - status.followup_date.days
      warning_period = 5.days

      found_rrs = user.reporting_relationships
                      .active
                      .where(client_status: status)
                      .where('last_contacted_at < ?', followup_date + warning_period)

      output[status.name] = found_rrs.pluck(:id) if found_rrs.present?
    end

    output
  end
end
