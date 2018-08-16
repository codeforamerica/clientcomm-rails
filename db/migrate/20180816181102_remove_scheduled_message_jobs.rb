class RemoveScheduledMessageJobs < ActiveRecord::Migration[5.1]
  def up
    Delayed::Job.where('handler ilike ?', '%ScheduledMessageJob%').destroy_all
  end
end
