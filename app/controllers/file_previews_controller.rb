class FilePreviewsController < ApplicationController
  # to use this, go to test.rb and add the line:
  # config.assets.debug = true
  # but, this'll make it very slow, so be sure to turn it off when
  # you don't need it
  def show
    render text: IO.read(params[:file])
  end
end
