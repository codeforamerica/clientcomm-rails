namespace :node_etl do
  task etl_users: :environment do
    num_users = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT count(cm.cmid)
      FROM cms cm
      WHERE cm.active = true
      AND cm.department IN (7, 4, 11, 3, 2);
    SQL
    groups = (num_users / 10.to_f).ceil

    Rails.logger.warn '--> beginning user load'
    imported_users = 0

    groups.times do |group|
      Rails.logger.warn { "--> Loading group #{group + 1} of #{groups}" }
      node_users = node_production.exec(<<-SQL, [group * 10])
        SELECT *
        FROM cms cm
        WHERE cm.active = true
        AND cm.department IN (7, 4, 11, 3, 2)
        ORDER BY cm.cmid
        LIMIT 10 OFFSET $1;
      SQL

      node_users.each do |node_user|
        first_name = "#{node_user['first'].strip} #{node_user['middle'].strip}"

        user = User.find_or_initialize_by(node_id: node_user['cmid']) do |u|
          u.full_name = "#{first_name} #{node_user['last'].strip}"
          u.email = node_user['email']
          u.password = 'xxxyyyzzz'
          u.password_confirmation = 'xxxyyyzzz'
          u.department = Department.first
        end

        imported_users += 1 if user.new_record?

        user.save!
      end
    end

    Rails.logger.warn { "--> user load of #{imported_users} users complete" }
  end

  task etl_clients: :environment do
    num_clients = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT COUNT(cl.clid)
      FROM clients cl
      LEFT JOIN cms cm ON cm.cmid = cl.cm
      WHERE cl.active = true
      AND cm.active = true
      AND cm.department IN (7, 4, 11, 3, 2);
    SQL

    groups = (num_clients / 10.to_f).ceil

    Rails.logger.warn '--> beginning client load'
    imported_clients = 0
    errored_clients = []

    groups.times do |group|
      Rails.logger.warn { "--> Loading group #{group + 1} of #{groups}" }
      node_clients = node_production.exec(<<-SQL, [group * 10])
        SELECT cl.*
        FROM clients cl
        LEFT JOIN cms cm ON cm.cmid = cl.cm
        WHERE cl.active = true
        AND cm.active = true
        AND cm.department IN (7, 4, 11, 3, 2)
        ORDER BY cl.clid
        LIMIT 10 OFFSET $1;
      SQL

      node_clients.each do |node_client|
        comms = node_production.exec(<<-SQL, [node_client['clid']])
          SELECT
          co.commid,
          co.value,
          cc.name
          FROM comms co
          LEFT JOIN commconns cc ON cc.comm = co.commid
          LEFT JOIN clients cl ON cl.clid = cc.client
          WHERE cl.clid = $1
          AND co.type = 'cell'
          AND cc.retired IS NULL;
        SQL

        user = User.find_by(node_id: node_client['cm'])

        multicomms = comms.count > 1
        comms.each_with_index do |comm, index|
          first_name = "#{node_client['first'].strip} #{node_client['middle'].strip}"
          comm_name = comm['name'].strip
          comm_name = index.to_s if comm_name.blank?
          last_name = node_client['last'].strip
          last_name = "#{last_name} (#{comm_name})" if multicomms

          client = Client.find_or_initialize_by(node_client_id: node_client['clid'], node_comm_id: comm['commid']) do |c|
            c.first_name = first_name
            c.last_name = last_name
            c.phone_number = comm['value']
            c.node_client_id = node_client['clid']
            c.node_comm_id = comm['commid']
            c.users = [user]
          end

          imported_clients += 1 if client.new_record?

          unless client.save
            Rails.logger.error("--> could not save client with clid:#{client.node_client_id} commid:#{client.node_comm_id} (#{client.full_name})")
            errored_clients << {
              clid: client.node_client_id,
              commid: client.node_comm_id,
              full_name: client.full_name,
              phone_number: client.phone_number,
              errors: client.errors.full_messages
            }
            imported_clients -= 1
            next
          end

          last_contacted_at = node_client['updated']
          if multicomms
            last_message = node_production.exec(<<-SQL, [comm['commid']])[0]
              SELECT m.created
              FROM comms co
              LEFT JOIN msgs m ON m.comm = co.commid
              LEFT JOIN convos cv ON cv.convid = m.convo
              WHERE co.commid = $1
              ORDER BY m.created DESC
              LIMIT 1;
            SQL

            if last_message.nil? || last_message['created'].blank?
              last_contacted_at = node_client['created']
              Rails.logger.warn("--> set last_contacted_at to #{last_contacted_at} because message.created was missing, for clid:#{client.node_client_id}, commid:#{comm['commid']}")
            else
              last_contacted_at = last_message['created']
              Rails.logger.warn("--> set last_contacted_at to #{last_contacted_at} instead of #{node_client['updated']} for clid:#{client.node_client_id}, commid:#{comm['commid']}")
            end
          end

          ReportingRelationship.find_by(user: user, client: client).update!(notes: node_client['otn'], last_contacted_at: last_contacted_at)
        end
      end
    end

    Rails.logger.warn { "--> client load of #{imported_clients} clients complete" }
    if errored_clients.count
      Rails.logger.warn { "--> #{errored_clients.count} clients not loaded!" }
      errored_clients.each_with_index do |ecs, index|
        Rails.logger.warn { "--> #{index}: #{ecs}" }
      end
    end
  end

  def node_production
    @client ||= PG::Connection.new(Rails.configuration.database_configuration['node_production'])
  end
end
