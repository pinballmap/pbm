Geocoder.configure(
  # street address geocoding service (default :nominatim)
  lookup: :mapbox,
  # lookup: :nominatim,

  # to use an API key:
  api_key: 'pk.eyJ1IjoicnlhbnRnIiwiYSI6ImNsZTV5dW11YTBoankzbnFsZTEzcnQycWsifQ._0FYgeHFSQCQJ6VboGXl8A',
  # api_key: ENV['MAPBOX_API_KEY'] ? ENV['MAPBOX_API_KEY'] : '',
  mapbox: {dataset: "mapbox.places"},

  # geocoding service request timeout, in seconds (default 3):
  timeout: 20,

  use_https: false,

  language: :en

)
