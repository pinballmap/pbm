class EventsController < InheritedResources::Base
  respond_to :html, :xml, :json, :rss, only: %i[index show]
  has_scope :region

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to @event, notice: 'Event was successfully created.'
    else
      render action: 'new'
    end
  end

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

  private
  def event_params
    params.require(:event).permit(:name, :long_desc, :start_date, :end_date, :region_id, :external_link, :category_no, :location_id, :category, :external_location_name, :ifpa_tournament_id, :ifpa_calendar_id)
  end
end
