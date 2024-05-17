Geocoder.configure(
  # street address geocoding service (default :nominatim)
  lookup: :google,
  # lookup: :nominatim,

  # to use an API key:
  api_key: ENV['GOOGLE_MAPS_API_KEY'] ? ENV['GOOGLE_MAPS_API_KEY'] : '',

  # geocoding service request timeout, in seconds (default 3):
  timeout: 20,

  use_https: false,

  language: :en

)
