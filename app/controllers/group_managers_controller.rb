class GroupManagersController < ApplicationController
  before_action :authenticate_admin!, only: [:index]
  before_action :set_app, only: [:index]
  before_action :check_authenticated_admin_or_manager, only: [:show, :add_manager_permission,:is_manager_permitted, :remove_manager_permission]
  before_action :set_manager_and_group, only: [:is_manager_permitted, :add_manager_permission, :remove_manager_permission]
  before_action :set_group_manager, only: [:destroy, :update]
  
  load_and_authorize_resource :except => [:show, :email_reset_password, :reset_password, :show_reset_token] 

  # GET /group_managers/
  def index
    render json: @app.group_managers
  end

  # GET /group_managers/:id
  def show
    # Validates only admins or the manager can see a certain manager
    if current_admin.nil? && current_group_manager != GroupManager.find(params[:id])
      return render json: GroupManager.new()
    end
    @group_manager = GroupManager.find(params[:id])
    if @group_manager[:password_godata]
      begin 
        crypt = ActiveSupport::MessageEncryptor.new(ENV['GODATA_KEY'])
        @group_manager.password_godata = crypt.decrypt_and_verify(@group_manager.password_godata)
      rescue
      end
    end
    render json: @group_manager
  end
  
  # GET /group_managers/:manager_id/:group_id
  def is_manager_permitted
    is_permitted = @manager.is_permitted?(@group)
    render json: { is_permitted: is_permitted, group: @group.get_path(string_only=true).join('/') }, status: :ok
  end

  def update
    if params[:group_manager][:vigilance_syndromes]
      @hashes = params[:group_manager][:vigilance_syndromes].each { |vs| vs.to_s }
      return if validate_hashes
          
      @group_manager.update_attribute(:vigilance_syndromes, @hashes)
    end
    if params[:group_manager][:password_godata]
      crypt = ActiveSupport::MessageEncryptor.new(ENV['GODATA_KEY'])
      encrypted_password = crypt.encrypt_and_sign(params[:group_manager][:password_godata])
      @group_manager.update_attribute(:password_godata, encrypted_password)
    end
    errors = {}
    update_params.except(:password_godata).each do |param|
      begin
        @group_manager.update_attribute(param[0], param[1])
      rescue ActiveRecord::InvalidForeignKey
        errors[param[0]] = param[1].to_s + ' não foi encontrado'
      rescue StandardError => msg
        errors[param[0]] = msg
      end
    end
    if errors.length == 0
      render json: @group_manager
    else
      render json: {errors: errors, group_manager: @group_manager}, status: :unprocessable_entity
    end
  end

  def destroy
    @group_manager.destroy!
  end

  def email_reset_password
    @group_manager = GroupManager.find_by_email(params[:email])
    aux_code = rand(36**4).to_s(36)
    reset_password_token = rand(36**10).to_s(36)
    @group_manager.update_attribute(:aux_code, aux_code)
    @group_manager.update_attribute(:reset_password_token, reset_password_token)
    if @group_manager.present?
      GroupManagerMailer.reset_password_email(@group_manager).deliver
    end
    render json: {message: "Email enviado com sucesso"}, status: :ok
  end

  def show_reset_token
    group_manager = GroupManager.where(aux_code: params[:code]).first
    if group_manager.present?
      render json: {reset_password_token: group_manager.reset_password_token}, status: :ok
    else
      render json: {error: true, message: "Codigo invalido"}, status: :bad_request
    end
  end

  def reset_password
    @group_manager = GroupManager.where(reset_password_token: params[:reset_password_token]).first
    if @group_manager.present?
      if @group_manager.reset_password(params[:password], params[:password_confirmation])
        render json: {error: false, message: "Senha redefinida com sucesso"}, status: :ok
      else
        render json: {error: true, data: @group_manager.errors}, status: :bad_request
      end
    else
      render json: {error: true, message: "Token invalido"}, status: :bad_request
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_app
      @app = App.find current_admin.app_id
    end

    def set_manager_and_group
      @manager = GroupManager.find(params[:group_manager_id])
      @group = Group.find(params[:group_id])
    end

    def set_group_manager
      @group_manager = GroupManager.find(params[:id])
    end

    def group_manager_params
      params.require(:group_manager).permit(:email, :password, :name, :app_id, :group_name, :twitter, :require_id, :id_code_length, :vigilance_email, :vigilance_syndromes, :username_godata, :password_godata)
    end

    def update_params
      params.require(:group_manager).permit(:email, :password, :name, :app_id, :group_name, :twitter, :require_id, :id_code_length, :vigilance_email, :username_godata, :password_godata, :userid_godata)
    end

    def check_authenticated_admin_or_manager
      if current_admin.nil? && current_group_manager.nil?
        return render json: {}, status: :ok
      end
    end

    def validate_hashes
      ids = []
      @hashes.each do |h|
        if ids.include? h[:syndrome_id]
          return render json: {errors: "Duplicated key syndrome_id"}, status: :unprocessable_entity
        elsif not h.key?("syndrome_id")
          return render json: {errors: "Missing key syndrome_id"}, status: :unprocessable_entity
        end
        ids.append(h[:syndrome_id])
      end
      return false
    end
    
end

# THIS IS A GROUP MANAGER PERMISSION GIVING SYSTEM
  # For now, as this feature is complex, this is comented. In the future, this will be patched to
  # be safe.

  # # GET /group_managers/:manager_id/:group_id/permit
  # def add_manager_permission
  #   # Validate either admin or manager with sufficient permissions
  #   if current_admin != nil || (current_manager != nil  && current_manager.is_permitted?(@group))
  #     ManagerGroupPermission::permit(@manager, @group)
  #     return render json: { error: false }, status: :ok
  #   end
  #   return render json: { error: true, message: 'Not enough permitions' }, status: :ok
  # end

  # # GET /group_managers/:manager_id/:group_id/unpermit
  # def remove_manager_permission
  #   # Validate either admin or manager with sufficient permissions
  #   if @manager == current_manager
  #     return render json: { error: true, message: 'Cannot unpermit yourself' }, status: :ok
  #   end
  #   if current_admin != nil || (current_manager != nil  && current_manager.is_permitted?(@group))
  #     ManagerGroupPermission.where(group_id: @group.id, manager_id: @manager.id).all.each do |p|
  #       p.destroy
  #     end
  #     return render json: { error: false }, status: :ok
  #   end
  #   return render json: { error: true, message: 'Not enough permitions' }, status: :ok
  # end

  # # GET /group_managers/:group_id/get_users
  # def get_users_in_manager_group

  # end

  # # DELETE /group_managers/:group_id/:user_id/remove_user_from_group
  # def remove_user_in_manager_group

  # end

  # # DELETE /group_managers/:group_id/:user_id/add_user_to_group
  # def add_users_in_manager_group

  # end