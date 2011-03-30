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
end
