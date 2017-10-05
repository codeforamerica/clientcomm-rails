class TemplatesController < ApplicationController
  before_action :authenticate_user!

  def index
    @templates = current_user.templates

    analytics_track(
      label: 'template_page_view',
      data: { templates_count: @templates.count }
    )
  end

  def new
    @template = Template.new
    @templates = current_user.templates

    analytics_track(label: 'template_create_view')
  end

  def create
    @template = Template.create(
      title: template_params[:title],
      body: template_params[:body],
      user_id: current_user.id
    )

    analytics_track(
      label: 'template_create_success',
      data: { message_length: @template.body.length }
    )

    if @template.valid?
      redirect_to templates_path
    else
      @templates = current_user.templates
      render :new
    end
  end

  def edit
    @template = current_user.templates.find(params[:id])
    @templates = current_user.templates

    analytics_track(label: 'template_edit_view')
  end

  def update
    @template = current_user.templates.find(params[:id])

    if @template.update_attributes(template_params)
      flash[:notice] = "Template updated"
      redirect_to templates_path
    else
      @templates = current_user.templates
      render 'edit'
    end
  end

  def destroy
    current_user.templates.find(params[:id]).destroy!

    analytics_track(
      label: 'template_delete',
      data: { templates_count: current_user.templates.count }
    )

    flash[:notice] = "Template deleted"
    redirect_to templates_path
  end

  private

  def template_params
    params.fetch(:template)
      .permit(:title, :body)
  end
end
