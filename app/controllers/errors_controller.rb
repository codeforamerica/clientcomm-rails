class ErrorsController < ApplicationController
  def not_found
    @title = 'ClientComm.org | Page not found (404)'

    render(status: 404)
  end

  def internal_server_error
    @title = 'ClientComm | There has been a problem on our end (500)'

    render(status: 500)
  end
end
