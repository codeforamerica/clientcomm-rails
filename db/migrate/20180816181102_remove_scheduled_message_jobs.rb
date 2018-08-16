class RemoveScheduledMessageJobs < ActiveRecord::Migration[5.1]
  def change
    Delayed::Job.where('handler ilike ?', '%ScheduledMessageJob%').destroy_all
  end
end
