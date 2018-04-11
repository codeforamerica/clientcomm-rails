namespace :node_etl do
  task :etl_users => :environment do
    num_users = node_production.exec('SELECT count(*) FROM cms WHERE cms.active = true;')[0]['count'].to_i
    groups = (num_users / 10.to_f).ceil

    Rails.logger.warn 'beginning user load'
    imported_users = 0

    groups.times do |group|
      Rails.logger.warn { "Loading group #{group + 1} of #{groups}" }
      node_users = node_production.exec("SELECT * FROM cms WHERE cms.active = true ORDER BY cms.cmid LIMIT 10 OFFSET #{group * 10};")

      node_users.each do |node_user|
        first_name = "#{node_user['first']} #{node_user['middle']}".strip

        user = User.find_or_initialize_by(node_id: node_user['cmid']) do |u|
          u.full_name = "#{first_name} #{node_user['last']}"
          u.email = node_user['email']
          u.password = 'xxxyyyzzz'
          u.password_confirmation = 'xxxyyyzzz'
          u.department = Department.first
        end

        imported_users += 1 if user.new_record?

        user.save!
      end
    end

    Rails.logger.warn { "user load of #{imported_users} users complete" }
  end

  def node_production
    @client ||= PG::Connection.new(Rails.configuration.database_configuration['node_production'])
  end
end
