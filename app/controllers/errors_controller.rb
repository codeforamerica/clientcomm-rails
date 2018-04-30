class ErrorsController < ApplicationController
  def not_found
    request.format = 'html'

    @title = 'ClientComm.org | Page not found (404)'

    respond_to do |format|
      format.any { render status: :not_found }
    end
  end

  def internal_server_error
    @title = 'ClientComm | There has been a problem on our end (500)'

    render(status: :internal_server_error)
  end
end
