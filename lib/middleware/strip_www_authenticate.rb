module Middleware
  class StripWwwAuthenticate
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers.delete("WWW-Authenticate") if status == 401 && env["PATH_INFO"].start_with?("/api/")
      [ status, headers, body ]
    end
  end
end
