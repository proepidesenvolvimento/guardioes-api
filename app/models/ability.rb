# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    case user
      when User
        can :create, Survey
        can :update, User
        can [:create, :update, :destroy], Household
        can :manage, Content
        # can :read, :all
      when Admin
        if user.is_god?
          can :manage, :all
        else 
          can [:manage], [AppSerializer, App, ContentSerializer, Content]
        end
      when Manager
        #can :create, user.permission.models_create
        can :read, [JWTBlacklist, AppSerializer, App, ContentSerializer, Content]
        #can :update, user.permission.models_update
        #can :destroy, user.permission.models_destroy
        can :manage, Content
      # when GroupManager
    end 
  end
end
