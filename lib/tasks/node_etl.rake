namespace :node_etl do
  task etl_users: :environment do
    num_users = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT count(cm.cmid)
      FROM cms cm
      WHERE cm.active = false
      AND cm.department IN (7, 4, 11, 3, 2);
    SQL
    groups = (num_users / 10.to_f).ceil
    logs = []

    logs << "--> beginning user load -- loading #{num_users} users"
    imported_users = 0

    groups.times do |group|
      logs << "--> Loading group #{group + 1} of #{groups}"
      node_users = node_production.exec(<<-SQL, [group * 10])
        SELECT *
        FROM cms cm
        WHERE cm.active = false
        AND cm.department IN (7, 4, 11, 3, 2)
        ORDER BY cm.cmid
        LIMIT 10 OFFSET $1;
      SQL

      node_users.each do |node_user|
        existing_user = User.find_by(node_id: node_user['cmid'])
        next unless existing_user.nil?

        first_name = "#{node_user['first'].strip} #{node_user['middle'].strip}"

        User.create(
          node_id: node_user['cmid'],
          full_name: "#{first_name} #{node_user['last'].strip}",
          email: node_user['email'],
          password: 'surcease-undulate-overlord-rebate-monad',
          password_confirmation: 'surcease-undulate-overlord-rebate-monad',
          department: Department.first,
          active: false
        )

        imported_users += 1
      end
    end

    logs.each do |log|
      Rails.logger.warn log
    end

    Rails.logger.warn { "--> user load of #{imported_users} users complete" }
  end

  task etl_inactive_messages: :environment do
    num_messages = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT COUNT(DISTINCT(msgs.tw_sid))
      FROM msgs
      INNER JOIN comms ON comms.commid = msgs.comm
      INNER JOIN convos ON convos.convid = msgs.convo
      INNER JOIN cms ON cms.cmid = convos.cm
      INNER JOIN clients ON clients.clid = convos.client
      WHERE comms.type = 'cell'
      AND msgs.tw_sid != ''
      AND cms.department IN (7, 4, 11, 3, 2)
      AND clients.active = false;
    SQL

    group_size = 1000
    groups = (num_messages / group_size.to_f).ceil

    Rails.logger.warn "--> beginning active message load of #{num_messages} messages in #{groups} groups."

    groups.times do |group|
      Rails.logger.warn { "--> Loading group #{group + 1} of #{groups}" }
      distinct_node_messages = node_production.exec(<<-SQL, [group_size, group * group_size])
        SELECT DISTINCT ON (msgs.tw_sid)
          msgs.tw_sid,
          msgs.msgid
        FROM msgs
        INNER JOIN comms ON comms.commid = msgs.comm
        INNER JOIN convos ON convos.convid = msgs.convo
        INNER JOIN cms ON cms.cmid = convos.cm
        INNER JOIN clients ON clients.clid = convos.client
        WHERE comms.type = 'cell'
        AND msgs.tw_sid != ''
        AND cms.department IN (7, 4, 11, 3, 2)
        AND clients.active = false
        ORDER BY msgs.tw_sid DESC
        LIMIT $1 OFFSET $2;
      SQL

      distinct_node_messages.each do |dist_msg|
        node_message_segments = node_production.exec(<<-SQL, [dist_msg['tw_sid']])
          SELECT
            convos.cm,
            msgs.comm,
            msgs.content,
            convos.convid,
            msgs.created,
            msgs.inbound,
            msgs.read,
            msgs.tw_sid,
            msgs.tw_status,
            comms.value
          FROM msgs
          INNER JOIN comms ON comms.commid = msgs.comm
          INNER JOIN convos ON convos.convid = msgs.convo
          WHERE msgs.tw_sid = $1
          ORDER BY msgs.msgid;
        SQL

        NodeMessagesImporter.import_message(node_message_segments)
      end
    end
  end

  task etl_clients: :environment do
    num_clients = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT COUNT(cl.clid)
      FROM clients cl
      LEFT JOIN cms cm ON cm.cmid = cl.cm
      WHERE cl.active = false
      AND cm.department IN (7, 4, 11, 3, 2);
    SQL

    groups = (num_clients / 10.to_f).ceil
    groups = 7
    logs = []

    logs << "--> beginning client load -- loading #{num_clients} clients"
    imported_clients = 0
    skipped_clients = 0
    errored_clients = []

    offset = 6
    groups -= offset
    groups.times do |group|
      group += offset
      logs << "--> Loading group #{group + 1} of #{groups + offset}"
      node_clients = node_production.exec(<<-SQL, [group * 10])
        SELECT cl.*
        FROM clients cl
        LEFT JOIN cms cm ON cm.cmid = cl.cm
        WHERE cl.active = false
        AND cm.department IN (7, 4, 11, 3, 2)
        ORDER BY cl.clid DESC
        LIMIT 10 OFFSET $1;
      SQL

      node_clients.each do |node_client|
        Rails.logger.warn "--> starting client #{node_client['clid']}"
        logs << "--> starting client #{node_client['clid']}"

        unless Client.find_by(node_client_id: node_client['clid']).nil?
          logs << "--> SKIPPING because client #{node_client['clid']} already exists!"
          skipped_clients += 1
          next
        end

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

        if comms.count.zero?
          logs << "--> SKIPPING because user #{node_client['clid']} has zero comms!"
          skipped_clients += 1
          next
        end

        user = User.find_by(node_id: node_client['cm'])
        if user.nil?
          logs << "--> SKIPPING because user #{node_client['cm']} doesn't exist!"
          skipped_clients += 1
          next
        end

        multicomms = comms.count > 1
        comms.each_with_index do |comm, index|
          first_name = "#{node_client['first'].strip} #{node_client['middle'].strip}"
          comm_name = comm['name'].strip
          comm_name = index.to_s if comm_name.blank?
          last_name = node_client['last'].strip
          last_name = "#{last_name} (#{comm_name})" if multicomms

          unless Client.find_by(phone_number: "+#{comm['value']}").nil?
            logs << "--> SKIPPING client #{node_client['clid']} + comm #{comm['commid']} because the phone number is taken!"
            skipped_clients += 1
            next
          end

          client = Client.new(
            node_client_id: node_client['clid'],
            node_comm_id: comm['commid'],
            first_name: first_name,
            last_name: last_name,
            phone_number: comm['value']
          )

          imported_clients += 1

          unless client.save
            logs << "--> could not save client with clid:#{client.node_client_id} commid:#{client.node_comm_id} (#{client.full_name})"
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

          logs << "--> saved client #{client.node_client_id}, setting last_contacted_at"

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
              logs << "--> set last_contacted_at to #{last_contacted_at} because message.created was missing, for clid:#{client.node_client_id}, commid:#{comm['commid']}"
            else
              last_contacted_at = last_message['created']
              logs << "--> set last_contacted_at to #{last_contacted_at} instead of #{node_client['updated']} for clid:#{client.node_client_id}, commid:#{comm['commid']}"
            end
          end

          rr = ReportingRelationship.find_by(user: user, client: client)
          logs << "--> WARNING found existing rr for client #{node_client['clid']} + user #{node_client['cm']}" unless rr.nil?
          rr ||= ReportingRelationship.create(user: user, client: client)
          rr.update!(active: false, last_contacted_at: last_contacted_at)
        end
      end
    end

    logs.each do |log|
      Rails.logger.warn log
    end

    Rails.logger.warn { "--> client load of #{imported_clients} clients complete" }

    if skipped_clients.positive?
      Rails.logger.warn { "--> #{skipped_clients} clients skipped!" }
    end

    if errored_clients.count
      Rails.logger.warn { "--> #{errored_clients.count} clients not loaded!" }
      errored_clients.each_with_index do |ecs, index|
        Rails.logger.warn { "--> #{index}: #{ecs}" }
      end
    end
  end

  task etl_notifications: :environment do
    num_notifications = node_production.exec(<<-SQL)[0]['count'].to_i
      SELECT count(n.notificationid)
      FROM notifications n
      WHERE n.sent = false
      AND n.closed = false
      AND n.send > now();
    SQL
    groups = (num_notifications / 10.to_f).ceil
    logs = []

    logs << "--> beginning notification load -- loading #{num_notifications} notifications"
    imported_notifications = 0

    groups.times do |group|
      logs << "--> Loading group #{group + 1} of #{groups}"
      node_notifications = node_production.exec(<<-SQL, [group * 10])
        SELECT *
        FROM notifications n
        WHERE n.sent = false
        AND n.closed = false
        AND n.send > now()
        ORDER BY n.notificationid
        LIMIT 10 OFFSET $1;
      SQL

      node_notifications.each do |node_notification|
        user = User.find_by(node_id: node_notification['cm'])
        client = Client.find_by(node_id: node_notification['client'])
        if user.nil? || client.nil?
          logs << "--> #{node_notification['notificationid']} Couldn't find user #{node_notification['cm']} and/or client #{node_notification['client']}"
          next
        end

        rr = ReportingRelationship.find_by(user: user, client: client)
        if rr.nil?
          logs << "--> #{node_notification['notificationid']} Couldn't find relationship between user #{node_notification['cm']} and client #{node_notification['client']}"
          next
        end

        send_at = node_notification['send']
        found_dupe = false

        rr.messages.scheduled.each do |existing_message|
          if ((node_notification[send] - existing_message.send_at) * 24 * 60).to_i.abs < 1 && node_notification['message'].strip == existing_message.body
            logs << "--> #{node_notification['notificationid']} found existing duplicate message with id #{existing_message.id}"
            found_dupe = true
          end
        end

        next if found_dupe

        message = Message.new(
          body: node_notification['message'].strip,
          reporting_relationship: rr,
          number_from: user.department.phone_number,
          number_to: client.phone_number,
          send_at: send_at,
          read: true
        )

        if message.invalid? || message.past_message?
          logs << "--> #{node_notification['notificationid']} Invalid message."
          next
        end

        imported_notifications += 1 if message.new_record?
        message.save!
        message.send_message
      end
    end

    logs.each do |log|
      Rails.logger.warn log
    end
  end

  def node_production
    @client ||= PG::Connection.new(Rails.configuration.database_configuration['node_production'])
  end
end
