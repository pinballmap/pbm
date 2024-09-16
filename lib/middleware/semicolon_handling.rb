class ReplaceSemicolonWithAmpersand
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['QUERY_STRING']
      # Modify query string if it exists
      env['QUERY_STRING'] = env['QUERY_STRING'].gsub(';', '&')
    end

    # Continue the request cycle
    @app.call(env)
  end
end
