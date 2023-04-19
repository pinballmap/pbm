Sentry.init do |config|
    config.dsn = 'https://849156c9c6914fa8a4a5bb07c51b2447@o1352308.ingest.sentry.io/4505037386219520'
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 1.0
    # or
    # config.traces_sampler = lambda do |context|
    #     true
    # end
    # config.enabled_environments = ['production']
end