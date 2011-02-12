class EventsController < InheritedResources::Base
  respond_to :xml, :json, :only => [:index, :show]
  belongs_to :region

  def index
    respond_with(@events = apply_scopes(Event).where('region_id = ?', @region.id))
  end
end
