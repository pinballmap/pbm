class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :detect_region, :set_current_user

  protected
    def detect_region
      @region = Region.find_by_name(params[:region].downcase) if (params[:region] && (params[:region].is_a? String))
    end

    def set_current_user
       Authorization.current_user = current_user
    end
end
