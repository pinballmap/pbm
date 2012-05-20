class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.region_id?
      can :access, :rails_admin
      can :dashboard
      if user.region.name == 'portland'
        can :manage, :all
      else
        can :manage, [LocationType]
        can [:update, :read], [Region], :id => user.region_id
        can :manage, [LocationPictureXref], :location => { :region_id => user.region_id }
        can :manage, [Location, Event, Operator, RegionLinkXref, Zone], :region_id => user.region_id
      end
    end
  end
end
