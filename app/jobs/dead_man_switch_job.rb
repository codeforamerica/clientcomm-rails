require 'aws-sdk'

class DeadManSwitchJob < ApplicationJob
  include ActionView::RecordIdentifier
  queue_as :dead_man_switch

  def perform
    cw = Aws::CloudWatch::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
    cw.put_metric_data(
      namespace: ENV['DEPLOY_BASE_URL'],
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
