module Api
  module V1
    # Upcoming events from our events table, which import_ifpa_tournaments keeps in sync with IFPA.
    class EventsController < BaseController
      MAX_RADIUS = 250
      MAX_RESULTS = 500
      NEARBY_PAGE_LIMIT = 50
      DISTANCE_UNITS = %w[m k].freeze
      # At a location the address is redundant, and the list shows everything the detail view would
      LOCATION_LIST_FIELDS = %i[id name start_date end_date ifpa_tournament_id external_link event_type long_desc].freeze
      DETAIL_FIELDS = %i[id ifpa_tournament_id name start_date end_date address external_location_name external_link event_type long_desc location_id].freeze
      PAGY_KEYS = %i[count first_url previous_url next_url page pages page_url previous next from to in last last_url limit options].freeze

      skip_before_action :verify_authenticity_token

      rate_limit to: 30, within: 1.minute, only: :index, name: "api_events_index"
      rate_limit to: 60, within: 1.minute, only: :show, name: "api_events_show"

      api :GET, "/api/v1/events.json", "Fetch upcoming events at a location, or near a point"
      description "Pass location_id, or lat, lon, and radius. Sorted by start date. " \
        "With location_id, returns at most #{MAX_RESULTS} events, each with #{LOCATION_LIST_FIELDS.join(', ')}. " \
        "Otherwise returns #{NEARBY_PAGE_LIMIT} events per page, with a pagy object for paging (pass page to fetch more), " \
        "each with #{DETAIL_FIELDS.join(', ')}, and location_name, which is null unless the event is at a Pinball Map location."
      param :location_id, Integer, desc: "Location ID", required: false
      param :lat, String, desc: "Latitude", required: false
      param :lon, String, desc: "Longitude", required: false
      param :radius, Integer, desc: "Search radius (max #{MAX_RADIUS})", required: false
      param :distance_unit, String, desc: "m (miles) or k (kilometers). Defaults to m", required: false
      param :start_date, String, desc: "YYYY-MM-DD, the client's local date, to hide events that already ended there. Must be within a day of the server's date", required: false
      param :page, Integer, desc: "Page number, for lat, lon, and radius searches. Defaults to 1", required: false
      formats [ "json" ]
      def index
        if params[:location_id].present?
          location_id = Integer(params[:location_id], exception: false)
          return render json: { error: "location_id must be an integer" }, status: :bad_request unless location_id&.positive?

          events = Event.where(location_id: location_id).select(*LOCATION_LIST_FIELDS).upcoming(upcoming_from).limit(MAX_RESULTS)
          return render json: { events: events.as_json(only: LOCATION_LIST_FIELDS) }
        end

        lat = Float(params[:lat], exception: false)
        lon = Float(params[:lon], exception: false)
        radius = Integer(params[:radius], exception: false)
        distance_unit = params[:distance_unit].presence || "m"

        unless lat&.between?(-90, 90) && lon&.between?(-180, 180) && radius&.between?(1, MAX_RADIUS) && DISTANCE_UNITS.include?(distance_unit)
          return render json: { error: "location_id, or lat, lon, and radius (1-#{MAX_RADIUS}) are required; distance_unit must be m or k" }, status: :bad_request
        end

        fields = DETAIL_FIELDS + %i[location_name]
        select = (DETAIL_FIELDS.map { |f| "events.#{f}" } + [ "locations.name AS location_name" ]).join(", ")
        events = Event.left_joins(:location).near([ lat, lon ], radius, units: distance_unit == "k" ? :km : :mi, select: select).upcoming(upcoming_from)
        pagy, events = pagy(events, limit: NEARBY_PAGE_LIMIT)

        render json: { events: events.as_json(only: fields), pagy: pagy.data_hash(data_keys: PAGY_KEYS) }
      end

      api :GET, "/api/v1/events/:id.json", "Fetch an event"
      description "Has #{DETAIL_FIELDS.join(', ')}, and location_name when the event is at a Pinball Map location."
      param :id, Integer, desc: "Event ID", required: true
      formats [ "json" ]
      def show
        event = Event.select(*DETAIL_FIELDS).find_by(id: params[:id])
        return render json: { error: "Event not found" }, status: :not_found unless event

        render json: { event: event.as_json(only: DETAIL_FIELDS).merge("location_name" => event.location_id && Location.where(id: event.location_id).pick(:name)) }
      end

      private

      def upcoming_from
        date = Date.iso8601(params[:start_date].to_s)
        (date - Date.current).abs <= 1 ? date : Date.current - Event::UPCOMING_GRACE_DAYS
      rescue Date::Error
        Date.current - Event::UPCOMING_GRACE_DAYS
      end
    end
  end
end
