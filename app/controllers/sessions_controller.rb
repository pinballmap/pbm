class SessionsController < Devise::SessionsController
  respond_to :json
  rate_limit to: 10, within: 20.minutes, only: :create
end
