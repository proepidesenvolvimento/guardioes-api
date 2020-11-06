class RegistrationController < Devise::RegistrationsController
  before_action :set_app, only: :create, if: -> { params[:user] }
  before_action :create_admin, if: -> { params[:admin] }
  before_action :create_group_manager, if: -> { params[:group_manager] }
  before_action :create_manager, if: -> { params[:manager] }

  respond_to :json
  
  def create
    if params[:user]
      build_resource(@new_sign_up_params)
      resource.save
  
      render_resource(resource)
    else
      build_resource(@sign_up_params)
      resource.save
  
      render_resource(resource)
    end
  end

  private
  def set_app
    if params[:user]
      if params[:user][:residence].blank?
        find_app = App.where(owner_country: params[:user][:country])
  
        if find_app.blank?
          name = params[:user][:country]
          app = App.create!(app_name: name, owner_country: name)
  
          puts "\n New Sign up Params App doesn't exist \n\n\n"
          puts @new_sign_up_params
          @new_sign_up_params = sign_up_params.merge(app_id: app.id).except(:residence)
          puts "\n\n\n"
        else
          puts "\n New Sign up Params App does exist \n\n\n"
          puts @new_sign_up_params
          @new_sign_up_params = sign_up_params.merge(app_id: find_app.first.id).except(:residence)
          puts "\n\n\n"
        end
      else
        find_app = App.where(owner_country: params[:user][:residence])
  
        if find_app.blank?
          name = params[:user][:residence]
          app = App.create!(app_name: name, owner_country: name)
  
          @new_sign_up_params = sign_up_params.merge(app_id: app.id).except(:residence)
        else
          @new_sign_up_params = sign_up_params.merge(app_id: find_app.first.id).except(:residence)
        end
      end
    end
  end

  def create_admin
    if ( params[:admin] && current_admin )
      if ((current_admin.is_god == false) && (params[:admin][:is_god] == true))
        @sign_up_params = nil
      else
        @sign_up_params = sign_up_params
      end
    end
  end 

  def create_manager
    if params[:manager] && current_admin
      @sign_up_params = sign_up_params
    else
      @sign_up_params = nil
    end
  end 

  def create_group_manager
    if params[:group_manager] && (current_admin || current_group_manager)
      @sign_up_params = sign_up_params
    else
      @sign_up_params = nil
    end
  end 


  def sign_up_params
    if params[:user]
      params.require(:user).permit(
        :email,
        :user_name,
        :birthdate,
        :country,
        :gender,
        :race,
        :is_professional,
        :password,
        :residence,
        :app_id,
        :picture,
        :state,
        :city,
        :identification_code,
        :group_id,
        :school_unit_id,
        :risk_group,
        :policy_version
      )
    elsif params[:admin]
      params.require(:admin).permit(
        :email,
        :password,
        :first_name,
        :last_name,
        :is_god,
        :app_id
      )
    elsif params[:group_manager]
      params.require(:group_manager).permit(
        :email,
        :name,
        :password,
        :app_id,
        :group_name,
        :require_id,
        :id_code_length,
        :twitter
      )
    elsif params[:manager]
      params.require(:manager).permit(
        :name,
        :email,
        :password,
        :app_id,
        permission_attributes: {
          models_create: [],
          models_delete: [],
          models_update: [],
          models_manage: []
        }
      )
    end
  end
end