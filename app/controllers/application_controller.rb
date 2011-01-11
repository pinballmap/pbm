class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :detect_region

  protected
    def detect_region
      @region = Region.find_by_name(params[:region].downcase) if params[:region]
    end
end
