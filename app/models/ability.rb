class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user && user.region_id?

    can :access, :rails_admin
    can :dashboard
    can :history
    can :manage, [Event, Operator, RegionLinkXref, Zone], region_id: user.region_id
    can :manage, [LocationMachineXref], location: { region_id: user.region_id }
    can [:update, :read], [LocationPictureXref], location: { region_id: user.region_id }
    can [:update, :read, :destroy], [MachineCondition, MachineScoreXref], location: { region_id: user.region_id }

    if user.is_super_admin
      can :manage, [Location]
      can :manage, [UserSubmission]
    else
      can :manage, [Location], region_id: user.region_id
    end

    if user.region.name == 'portland'
      can :manage, [Region, Machine, MachineGroup, User, BannedIp, LocationType]
    elsif user.is_machine_admin
      can [:update, :read], [Region], id: user.region_id
      can :manage, [Machine, MachineGroup]
    else
      can [:update, :read], [Region], id: user.region_id
    end
  end
end
