class ManagersController < ApplicationController
  # before_action :authenticate_admin!, only: [:index]
  before_action :set_manager, only: [:show, :update, :destroy]
  before_action :set_app, only: [:index]
  

  def index
    begin
      authorize! :read, @app.managers, :message => "Permissão insuficiente para visualizar Gerentes"
      render json: @app.managers
    rescue => exception
      render json: { error: exception }, status: :unauthorized
    end
  end

  # GET /managers/:id
  def show
    render json: Manager.find(params[:id])
  end

  def update
    if @manager.update(manager_params)
      render json: @manager
    else
      render json: @manager.errors, status: :unprocessable_entity
    end
  end

  # DELETE /managers/:id
  def destroy
    @manager.destroy!
  end

  private

  def set_manager
    @manager = Manager.find(params[:id])
  end

  def set_app
    @app = App.find current_admin.app_id
  end

  def manager_params
    params.require(:manager).permit(
        :name,
        :email,
        :password,
      )
  end 
end