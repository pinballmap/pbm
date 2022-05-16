Apipie.configure do |config|
  config.app_name                = "pinballmap.com API"
  config.api_base_url            = ""
  config.doc_base_url            = "/api/v1/docs"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/*.rb"
  config.validate                = false
  config.translate               = false
  config.api_routes              = Rails.application.routes
  config.app_info = "
    If you use this API for something cool, please let us know, we like looking at interesting uses of the data.
    If you have any suggestions/requests for endpoints, please email: admin@pinballmap.com.
    If you have any patches that you'd like to submit to the API, please check out: https://github.com/pinballmap/pbm.
    If you use this data, please include attribution.
  "
end
