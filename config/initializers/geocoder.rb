Geocoder.configure(

  timeout: 20,

  google: {
    api_key: ENV['GOOGLE_MAPS_API_KEY'] ? ENV['GOOGLE_MAPS_API_KEY'] : ''
  },

  mapbox: {
    api_key: ENV['MAPBOX_GEOCODE_API_KEY'] ? ENV['MAPBOX_GEOCODE_API_KEY'] : ''
  },

  use_https: false,

  language: :en

)
