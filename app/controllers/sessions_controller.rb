class SessionsController < Devise::SessionsController
  respond_to :json
  rate_limit to: 10, within: 20.minutes, only: :create, name: "sessions_create"
  before_action :store_referer_location, only: :new

  private

  # Map searches update the URL client-side via pushState, so the server never
  # sees them. The referer reflects the browser's actual URL, so prefer it.
  def store_referer_location
    referer = URI.parse(request.referer.to_s)
    return unless referer.host == request.host && referer.port == request.port
    return if referer.path.blank? || NO_RETURN_PATHS.include?(referer.path)

    session[:previous_url] = referer.request_uri
  rescue URI::InvalidURIError
    nil
  end
end
