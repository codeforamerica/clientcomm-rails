module ClientStatusHelper
  def client_statuses
    @output = {}

    days_lookup = { 'Active' => 30, 'Training' => 30, 'Exited' => 90 }
    notice_days = 5

    ClientStatus.all.each do |status|
      if (due_date = days_lookup.fetch(status.name, nil))
        followup_date = Time.now - (due_date - notice_days).days
        found_clients = Client.where(["client_status_id = :id and last_contacted_at < :followup_date", {id: status.id, followup_date: followup_date}])

        if found_clients.count > 0
          @output[status.name] = {
            clients: found_clients,
            client_ids: found_clients.each { |c| c.id }
          }
        end
      end
    end

    @output
  end
end
