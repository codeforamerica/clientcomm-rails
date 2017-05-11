class ClientsController < ApplicationController
    def index
    end

    def new
        @client = Client.new
    end
end
