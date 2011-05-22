require 'pony'

class PagesController < ApplicationController
  def region
    @location_count = @region.locations.size
    @lmx_count = @region.location_machine_xrefs.size

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => LocationType.all.sort{|a,b| a.name <=> b.name},
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Location.where('region_id = ?', @region.id).order('name'),
        'autocomplete' => 1,
      },
      'machine' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => @region.machines,
        'autocomplete' => 1,
      },
      'zone' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Zone.where('region_id = ?', @region.id).order('name'),
      },
      'operator' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Operator.where('region_id = ?', @region.id).order('name'),
      },
      'city' => {
        'id'   => 'city',
        'name' => 'city',
        'search_collection' => Location.find(:all, :conditions => ['region_id = ?', @region.id], :select => 'distinct city', :order => 'city'),
      }
    }

    render "#{@region.name}/region" if (template_exists?("#{@region.name}/region"))
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
    render "#{@region.name}/about" if (template_exists?("#{@region.name}/about"))
  end

  def links
    @links = Hash.new
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.sort_order || 0] ||= []) << rlx
    end

    render "#{@region.name}/links" if (template_exists?("#{@region.name}/links"))
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    if (verify_recaptcha)
      flash[:notice] = "Thanks for entering that location. We'll get it in the system as soon as possible."
      Pony.mail(:to => @region.users.collect {|u| u.email}, :from => 'admin@pinballmap.com', :subject => 'Hello', :body => 'you entered it right')
    else
      flash[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
    end
  end

  def suggest_new_location
    @states = Location.find_all_by_region_id(@region.id).collect {|r| r.state}.uniq.sort
  end

  def apps
  end

  def app_support
  end

  def contact
  end

  def home
  end
end
