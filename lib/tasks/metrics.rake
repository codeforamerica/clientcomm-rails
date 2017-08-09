namespace :metrics do
  task :generate => :environment do
    puts MetricsGenerator.generate
  end
end
