Geocoder.configure(
  # street address geocoding service (default :nominatim)
  lookup: :google,
  api_key: ENV.fetch('GOOGLE_MAPS_API_KEY', ''),
  
  here: {
    api_key: ENV.fetch('HERE_MAPS_API_KEY', ''),
  },

  ip_lookup: :geoip2,
    geoip2: {
    file:
            if ENV['GEO_BUCKET']
              Aws::S3::Resource.new.bucket(ENV['GEO_BUCKET']).object('maxmind/GeoLite2-City.mmdb').download_file('tmp/GeoLite2-City.mmdb') ? "tmp/GeoLite2-City.mmdb" : ''
            else
              'tmp/GeoLite2-City.mmdb'
            end
  },
  # geocoding service request timeout, in seconds (default 3):
  timeout: 20,
  use_https: true,
  language: :en,
  # logger: Rails.logger,
  # kernel_logger_level: ::Logger::DEBUG
)
