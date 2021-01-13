Rails.application.routes.draw do
  resources :twitter_apis
  resources :pre_registers
  resources :messages
  resources :syndromes
  resources :school_units
  resources :permissions, only: [:create, :update, :show, :destory]
  post "school_units_list", to: 'school_units#index_filtered'
  post "upload_by_file", to: 'school_units#upload_by_file'


  get "groups/root", to: 'groups#root'
  post '/groups/build_country_city_state_groups', to: 'groups#build_country_city_state_groups'
  post "groups/upload_group_file", to: 'groups#upload_group_file'
  get "groups/:id/get_path", to: 'groups#get_path'
  get "groups/:id/get_children", to: 'groups#get_children'
  get "groups/:id/get_twitter", to: 'groups#get_twitter'
  resources :groups

  get 'data_visualization/users_count', to: 'data_visualization#users_count'
  get 'data_visualization/surveys_count', to: 'data_visualization#surveys_count'
  get 'data_visualization/asymptomatic_surveys_count', to: 'data_visualization#asymptomatic_surveys_count'
  get 'data_visualization/symptomatic_surveys_count', to: 'data_visualization#symptomatic_surveys_count'

  get "dashboard", to: 'dashboard#index'
  
  resources :symptoms
  resources :public_hospitals
  post "public_hospital_admin", to: "public_hospitals#render_public_hospital_admin"
  resources :contents

  get "apps/:id/get_twitter", to: 'apps#get_twitter'
  resources :apps

  resources :rumors

  get "surveys/school_unit/:id", to: "surveys#group_data"
  get "users/school_unit/:id", to: "users#group_data"

  get "analysis/:id", to: "users#analysis"
  
  get "surveys/all_surveys", to: "surveys#all_surveys"
  #get "surveys/week", to: "surveys#weekly_surveys"
  #get "surveys/week_limited", to: "surveys#limited_surveys"
  get "surveys/week", to: "surveys#limited_surveys"
  get "surveys/render_without_user", to: "surveys#render_without_user"
  get "surveys/to_csv/:begin/:end/:key", to: "surveys#surveys_to_csv"
  post "email_reset_password", to: "users#email_reset_password"
  post "show_reset_token", to: "users#show_reset_token"
  post "reset_password", to: "users#reset_password"

  resources :users do
    resources :households
    resources :surveys
  end
  post "render_user_by_filter",to: "users#query_by_param"
  patch "admin_update/:id", to: "users#admin_update"
  resources :rumors

  scope "/user" do 
    post "reset_password", to: "users#reset_password"
    get "/panel", to: "users#panel_list"
  end

  scope "/admins" do 
    post "email_reset_password", to: "admins#email_reset_password"
    post "show_reset_token", to: "admins#show_reset_token"
    post "reset_password", to: "admins#reset_password"
  end
  resources :admins, only: [:index, :update, :destroy]
  
  devise_for :admins,
    path: 'admin/',
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: 'session',
      registrations: 'registration'
    }

    resources :group_managers
    get 'group_managers/:group_manager_id/:group_id', to: 'group_managers#is_manager_permitted'
    scope "/group_manager" do 
      post "email_reset_password", to: "group_managers#email_reset_password"
      post "show_reset_token", to: "group_managers#show_reset_token"
      post "reset_password", to: "group_managers#reset_password"
    end
    # IN THE FUTURE THE FOLLOWING FUTURES WILL BE IMPLEMENTED
    # get 'group_managers/:manager_id/:group_id/permit', to: 'group_managers#add_manager_permission'
    # get 'group_managers/:manager_id/:group_id/unpermit', to: 'group_managers#remove_manager_permission'
    devise_for :group_managers,
    path: 'group_manager/',
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "signup"
    },
    controllers: {
      sessions: 'session',
      registrations: 'registration'
    }

    resources :managers
    scope "/manager" do 
      post "email_reset_password", to: "managers#email_reset_password"
      post "show_reset_token", to: "managers#show_reset_token"
      post "reset_password", to: "managers#reset_password"
    end
    devise_for :managers,
      path: "manager/",
      path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup"
      },
      controllers: {
        sessions: "session",
        registrations: "registration",
      }

    devise_for :users,
      path: "/user",
      path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup"
      },
      controllers: {
        sessions: "session",
        registrations: "registration",
        # passwords: "passwords"
      }

    root to: "admin#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
