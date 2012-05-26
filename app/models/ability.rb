class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.region_id?
      can :access, :rails_admin
      can :dashboard
      can :history
      if user.region.name == 'portland'
        can :manage, [LocationType, Region, Machine]
        can [:update, :read], [LocationPictureXref], :location => { :region_id => user.region_id }
        can :manage, [Location, Event, Operator, RegionLinkXref, Zone], :region_id => user.region_id
      else
        can :manage, [LocationType]
        can [:update, :read], [Region], :id => user.region_id
        can [:update, :read], [LocationPictureXref], :location => { :region_id => user.region_id }
        can :manage, [Location, Event, Operator, RegionLinkXref, Zone], :region_id => user.region_id
      end
    end
  end
end
