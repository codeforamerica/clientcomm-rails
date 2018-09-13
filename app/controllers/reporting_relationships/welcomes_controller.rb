module ReportingRelationships
  class WelcomesController < ApplicationController
    before_action :authenticate_user!

    def new
      rr = ReportingRelationship.find params[:reporting_relationship_id]
      @client = rr.client
      salutation = 'Good afternoon'
      salutation = 'Good morning' if Time.zone.now < Time.zone.now.noon
      @welcome_body = t(
        'message.welcome',
        salutation: salutation,
        client_full_name: @client.full_name,
        user_last_name: rr.user.full_name.split(' ').last
      )
    end

    def create
      rr = ReportingRelationship.find params[:reporting_relationship_id]

      respond_to do |format|
        format.html { redirect_to reporting_relationship_path(rr) }
        format.js { head :no_content }
      end
    end

    private

    def message_params
      params.require(:message)
            .permit(:body)
    end
  end
end
