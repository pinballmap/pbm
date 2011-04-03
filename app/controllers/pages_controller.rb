require 'pony'

class PagesController < ApplicationController
  def home
  end

  def region
    @location_count = @region.locations.size
    @lmx_count = @region.location_machine_xrefs.size
  end

  def contact
  end

  def about
  end

  def newlocation
  end

  def apps
  end

  def appsupport
  end

  def links
  end

  def highrollers
  end

  def submitted_new_location
    if (verify_recaptcha)
      flash[:notice] = "Thanks for entering that location. We'll get it in the system as soon as possible."
      Pony.mail(:to => @region.users.collect {|u| u.email}, :from => 'admin@pinballmap.com', :subject => 'Hello', :body => 'you entered it right')
    else
      flash[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
    end
  end
end
