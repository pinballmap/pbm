class EventsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def index
    @events = apply_scopes(Event)
    @events.select!(&:active?)

    respond_to do |format|
      format.html do
        @sorted_events = {}
        @events.each do |e|
          category = e.category.blank? ? 'General' : e.category
          (@sorted_events[category] ||= []) << e
        end

        render "#{@region.name}/events" if lookup_context.find_all("#{@region.name}/events").any?
      end
      format.xml { respond_with @events }
      format.json { respond_with @events }
      format.rss { respond_with @events }
    end
  end
end
