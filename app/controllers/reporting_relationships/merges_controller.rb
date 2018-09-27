module ReportingRelationships
  class MergesController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :intercom_rails_auto_include

    def create
      redirect_to clients_path
    end

    private

    def merge_params
      params.require(:reporting_relationship)
            .permit(:user_id, :client_id)
    end
  end
end
