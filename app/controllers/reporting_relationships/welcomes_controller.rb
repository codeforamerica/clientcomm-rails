module ReportingRelationships
  class WelcomesController < ApplicationController
    before_action :authenticate_user!

    def new
      @reporting_relationship = ReportingRelationship.find params[:reporting_relationship_id]
      salutation = 'Good afternoon'
      salutation = 'Good morning' if Time.zone.now < Time.zone.now.noon
      @welcome_body = t(
        'message.welcome',
        salutation: salutation,
        client_full_name: @reporting_relationship.client.full_name,
        user_last_name: @reporting_relationship.user.full_name.split(' ').last
      )
    end
  end
end
