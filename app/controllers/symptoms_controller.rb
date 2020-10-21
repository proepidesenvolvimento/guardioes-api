class SymptomsController < ApplicationController
  before_action :set_user, :index
  authorize_resource :class => false
  before_action :authenticate_admin!, except: [:index]
  before_action :set_symptom, only: [:show, :update, :destroy]

  # GET /symptoms
  def index
    @symptoms = Symptom.filter_symptom_by_app_id(@user.app_id)

    begin
      authorize! :read, :symptom
      render json: @symptoms
    rescue => exception
      render json: { error: exception }, status: :unauthorized
    end
  end

  # GET /symptoms/1
  def show
    render json: @symptom
  end

  # POST /symptoms
  def create
    @symptom = Symptom.new(symptom_params)

    if @symptom.save
      render json: @symptom, status: :created, location: @symptom
    else
      render json: @symptom.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /symptoms/1
  def update
    if @symptom.update(symptom_params)
      render json: @symptom
    else
      render json: @symptom.errors, status: :unprocessable_entity
    end
  end

  # DELETE /symptoms/1
  def destroy
    SyndromeSymptomPercentage.where(symptom:@symptom).each do |obj|
      obj.destroy
    end
    @symptom.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_symptom
      @symptom = Symptom.find(params[:id])
    end

    def set_user
      if current_user.nil? && current_manager.nil?
        @user = current_admin
      elsif current_admin.nil? && current_user.nil?
        @user = current_manager
      else
        @user = current_user
      end
    end

    # Only allow a trusted parameter "white list" through.
    def symptom_params
      params.require(:symptom).permit(:description, :code, :priority, :details, :app_id, message_attributes: [ :title, :warning_message, :go_to_hospital_message ])
    end
end
