# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    case user
      when Admin
        if user.is_god?
          can :manage, :all
        else 
          can [:manage], [:manager, :group_manager, :symptom, :syndrome, :content, :user]
        end
      when Manager
        can :create, user.permission.models_create
        can :read, user.permission.models_read
        can :update, user.permission.models_update
        can :destroy, user.permission.models_destroy
        can :manage, user.permission.models_destroy
      when GroupManager
        can :manage, :user
    end 
  end
end
