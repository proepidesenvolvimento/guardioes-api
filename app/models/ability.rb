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
        # can :read, :all
      when Admin
        if user.is_god?
          can :manage, :all
        else
          can :manage, [ Manager, GroupManager, Symptom, Syndrome, Content, User]
        end
      # when Manager
      # when GroupManager
    end
  end
end
