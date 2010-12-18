class ApplicationController < ActionController::Base
  protect_from_forgery
  autocomplete :location, :name
end
