class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.region_id?
      can :access, :rails_admin
      can :dashboard
      can :history
      can :manage, [LocationType]
      can :manage, [Location, Event, Operator, RegionLinkXref, Zone], :region_id => user.region_id
      can :manage, [LocationMachineXref], :location => { :region_id => user.region_id }
      can [:update, :read], [LocationPictureXref], :location => { :region_id => user.region_id }
      can [:update, :read, :destroy], [MachineScoreXref], :location => { :region_id => user.region_id }

      if (user.region.name == 'portland')
        can :manage, [Region, Machine, User, BannedIp]
      elsif (user.is_machine_admin)
        can [:update, :read], [Region], :id => user.region_id
        can :manage, [Machine]
      else
        can [:update, :read], [Region], :id => user.region_id
      end

    end
  end
end
