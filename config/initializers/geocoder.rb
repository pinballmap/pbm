Geocoder.configure(
  # street address geocoding service (default :nominatim)
  lookup: :google,
  api_key: ENV.fetch('GOOGLE_MAPS_API_KEY', ''),

  by_manufacturer: {
    api_key: ENV.fetch('GOOGLE_MAPS_API_KEY_BY_ADDRESS', '')
  },
  
  here: {
    api_key: ENV.fetch('HERE_MAPS_API_KEY', ''),
  },

  nominatim: {
    http_headers: { "User-Agent" => "Pinball Map - admin@pinballmap.com" }
  },

  # geocoding service request timeout, in seconds (default 3):
  timeout: 20,
  use_https: true,
  language: :en,
  # logger: Rails.logger,
  # kernel_logger_level: ::Logger::DEBUG
)
