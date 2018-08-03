require 'aws-sdk'

class DeadManSwitchJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :dead_man_switch

  def perform
    CLOUD_WATCH.put_metric_data(
      namespace: ENV['DEPLOYMENT'],
      metric_data: [
        {
          metric_name: 'DeadManSwitchRan',
          timestamp: Time.zone.now,
          value: 1.0,
          unit: 'None',
          storage_resolution: 1
        }
      ]
    )
  end
end
