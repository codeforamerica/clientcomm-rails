CLOUD_WATCH = if ENV['AWS_SECRET_ACCESS_KEY']
                Aws::CloudWatch::Client.new(
                  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
                  region: 'us-east-1'
                )
              else
                Aws::CloudWatch::Client.new(stub_responses: true)
              end
