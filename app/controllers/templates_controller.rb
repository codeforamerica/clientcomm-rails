class TemplatesController < ApplicationController
  before_action :authenticate_user!

  def index
    @templates = current_user.templates

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @template = Template.new
    @templates = current_user.templates
  end

  def create
    @template = Template.create(
      title: template_params[:title],
      body: template_params[:body],
      user_id: current_user.id
    )

    if @template.valid?
      redirect_to templates_path
    else
      render :new
    end
  end

  def edit
    @template = current_user.templates.find(params[:id])
    @templates = current_user.templates
  end

  def update
    @template = current_user.templates.find(params[:id])

    if @template.update_attributes(template_params)
      flash[:notice] = "Template updated"
      redirect_to templates_path
    else
      render 'edit'
    end
  end

  private

  def template_params
    params.fetch(:template, {})
      .permit(:title, :body)
  end
end
