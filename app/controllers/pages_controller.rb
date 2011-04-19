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

  def contact_sent
      Pony.mail(
        :to => @region.users.collect {|u| u.email},
        :from => 'admin@pinballmap.com',
        :subject => "Message from #{@region.full_name} pinball map",
        :body => [params['contact_name'], params['contact_email'], params['contact_msg']].join("\n")
      )
  end

  def about
  end

  def apps
  end

  def app_support
  end

  def links
    @links = Hash.new
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.sort_order || 0] ||= []) << rlx
    end
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def suggest_new_location
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
