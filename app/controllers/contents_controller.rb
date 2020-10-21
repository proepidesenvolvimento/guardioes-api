class ContentsController < ApplicationController
  # before_action :authenticate_admin!, only: [:create, :destroy, :update]
  
  before_action :set_user, :index
  before_action :set_content, only: [:show, :update, :destroy]
  

  # GET /contents
  def index
    @contents = Content.user_country(@user.app_id)

    begin
      authorize! :read, :content
      render json: @contents
    rescue => exception
      render json: { error: exception }, status: :unauthorized
    end
  end

  # GET /contents/1
  def show
    begin
      authorize! :read, @user
      render json: @content
    rescue => exception
      render json: { error: exception }, status: :unauthorized
    end
  end

  # POST /contents
  def create
    @content = Content.new(content_params)

    begin
      authorize! :create, current_manager
      if @content.save
        render json: @content, status: :created, location: @content
      else
        render json: @content.errors, status: :unprocessable_entity
      end
    rescue => exception
      render json: { error: exception }, status: :unauthorized
    end
  end

  # PATCH/PUT /contents/1
  def update
    if @content.update(content_params)
      render json: @content
    else
      render json: @content.errors, status: :unprocessable_entity
    end
  end

  # DELETE /contents/1
  def destroy
    @content.destroy

    head :no_content
  end

  def check_authenticated_admin_or_manager
    if current_admin.nil? && current_group_manager.nil?
      return render json: {}, status: :ok
    end
  end

  private
  def set_user
    if current_user.nil? && current_manager.nil?
      @user = current_admin
    elsif current_admin.nil? && current_user.nil?
      @user = current_manager
      @type = 'current_manager'
    else
      @user = current_user
    end
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_content
      @content = Content.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def content_params
      params.require(:content).permit(:title, :body, :icon, :content_type, :app_id, :source_link)
    end
end
