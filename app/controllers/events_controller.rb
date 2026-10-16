class EventsController < ApplicationController
  respond_to :xml, :json, :rss, only: %i[index]
  has_scope :region
  def index
    @events = apply_scopes(Event)
    @events.select!(&:active?)

    respond_to do |format|
      format.html do
        @sorted_events = {}
        @events.each do |e|
          category = e.category.blank? ? "General" : e.category
          (@sorted_events[category] ||= []) << e
        end

        render "#{@region.name}/events" if lookup_context.find_all("#{@region.name}/events").any?
      end
      format.xml { respond_with @events }
      format.json { respond_with @events }
      format.rss { respond_with @events }
    end
  end

  def list_within_range
    unless params.dig(:boundsData, :sw, :lat)
      return render plain: "boundsData param (with sw/ne lat/lng) is required", status: :bad_request
    end

    bounds = [ params[:boundsData][:sw][:lat], params[:boundsData][:sw][:lng],
               params[:boundsData][:ne][:lat], params[:boundsData][:ne][:lng] ]

    @pagy, @events = pagy(Event.upcoming.within_bounding_box(bounds).includes(:location))
    render partial: "maps/events", locals: { pagy: @pagy, events: @events }
  end
end
