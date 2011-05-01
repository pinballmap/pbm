class EventsController < InheritedResources::Base
  respond_to :html, :xml, :json, :only => [:index, :show]
  has_scope :region

  def index
    @events = apply_scopes(Event)

    respond_to do |format|
      format.html do
        @sorted_events = Hash.new
        @events.each {|e|
          (@sorted_events[e.category || 'General'] ||= []) << e
        }

        render "#{@region.name}/events" if (template_exists?("#{@region.name}/events"))
      end
      format.xml { respond_with @events }
    end
  end
end
