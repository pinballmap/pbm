module Api
  module V1
    # Proxies Google Places (legacy) autocomplete and details requests so the mobile app
    # doesn't need to ship a Google API key. Paths mirror Google's so the app's
    # react-native-google-places-autocomplete can point its requestUrl at /api/v1/places.
    class PlacesController < BaseController
      GOOGLE_PLACES_ROOT = "https://maps.googleapis.com/maps/api/place".freeze

      # Places Details is billed by the fields requested. Only ask for what
      # SuggestLocation's setLocation uses, regardless of what the client sends.
      DETAILS_FIELDS = %w[
        name place_id formatted_address address_components website formatted_phone_number international_phone_number
      ].join(",").freeze

      MAX_INPUT_LENGTH = 200
      SESSIONTOKEN_FORMAT = /\A[A-Za-z0-9-]{1,64}\z/
      LANGUAGE_FORMAT = /\A[A-Za-z]{2,3}(-[A-Za-z0-9]{2,4})?\z/
      PLACE_ID_FORMAT = /\A[A-Za-z0-9_-]{1,512}\z/

      # Backstop against runaway usage across all users. Google Cloud quotas are the real hard stop.
      DAILY_LIMITS = {
        "autocomplete" => ENV.fetch("PLACES_AUTOCOMPLETE_DAILY_LIMIT", 2000).to_i,
        "details" => ENV.fetch("PLACES_DETAILS_DAILY_LIMIT", 100).to_i
      }.freeze

      before_action :require_api_user
      rate_limit to: 60, within: 1.minute, by: -> { current_user.id }, only: :autocomplete, name: "api_places_autocomplete"
      rate_limit to: 300, within: 1.day, by: -> { current_user.id }, only: :autocomplete, name: "api_places_autocomplete_daily"
      rate_limit to: 5, within: 1.minute, by: -> { current_user.id }, only: :details, name: "api_places_details"
      rate_limit to: 20, within: 1.day, by: -> { current_user.id }, only: :details, name: "api_places_details_daily"
      before_action :enforce_daily_limit

      api :GET, "/api/v1/places/place/autocomplete/json", "Proxy for Google Places autocomplete"
      description "Proxies Google Places autocomplete. Requires user_email and user_token (params or X-User-Email/X-User-Token headers)."
      param :input, String, desc: "Text to autocomplete", required: true
      param :language, String, desc: "Language code, e.g. en", required: false
      param :sessiontoken, String, desc: "Places session token", required: false
      formats [ "json" ]
      def autocomplete
        input = params[:input].to_s.strip
        return render_places_error("input is required") if input.blank? || input.length > MAX_INPUT_LENGTH

        forward("autocomplete", { input: input }.merge(common_params))
      end

      api :GET, "/api/v1/places/place/details/json", "Proxy for Google Places details"
      description "Proxies Google Places details with a fixed set of fields. Requires user_email and user_token (params or X-User-Email/X-User-Token headers)."
      param :placeid, String, desc: "Google place_id", required: true
      param :language, String, desc: "Language code, e.g. en", required: false
      param :sessiontoken, String, desc: "Places session token", required: false
      formats [ "json" ]
      def details
        placeid = params[:placeid].to_s
        return render_places_error("placeid is required") unless placeid.match?(PLACE_ID_FORMAT)

        forward("details", { placeid: placeid, fields: DETAILS_FIELDS }.merge(common_params))
      end

      private

      def enforce_daily_limit
        limit = DAILY_LIMITS[action_name]
        count = Rails.cache.increment("places:#{action_name}:#{Date.current}", 1, expires_in: 2.days)
        return unless count && count > limit

        Rails.logger.warn("Places #{action_name} daily limit of #{limit} reached")
        render json: { status: "OVER_QUERY_LIMIT", error_message: "Place search is temporarily unavailable." }, status: :service_unavailable
      end

      def common_params
        forwarded = {}
        forwarded[:language] = params[:language] if params[:language].to_s.match?(LANGUAGE_FORMAT)
        forwarded[:sessiontoken] = params[:sessiontoken] if params[:sessiontoken].to_s.match?(SESSIONTOKEN_FORMAT)
        forwarded
      end

      def forward(endpoint, query)
        uri = URI("#{GOOGLE_PLACES_ROOT}/#{endpoint}/json")
        uri.query = URI.encode_www_form(query.merge(key: ENV.fetch("GOOGLE_PLACES_API_KEY", "")))

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
          http.get(uri.request_uri)
        end

        render json: response.body, status: response.code.to_i
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
        Rails.logger.error("Places #{endpoint} request failed: #{e.class}: #{e.message}")
        render json: { status: "UNKNOWN_ERROR", error_message: "Place search failed." }, status: :bad_gateway
      end

      def render_places_error(message)
        render json: { status: "INVALID_REQUEST", error_message: message }, status: :bad_request
      end
    end
  end
end
