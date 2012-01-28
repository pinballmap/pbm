require 'pony'

class PagesController < ApplicationController
  def region
    @location_count = @region.locations.size
    @lmx_count = @region.location_machine_xrefs.size

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Location.find(:all, :conditions => ['region_id = ? and location_type_id is not null', @region.id], :select => 'distinct location_type_id').collect { |l| l.location_type }.sort {|a,b| a.name <=> b.name},
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
      flash.now[:notice] = "Thanks for entering that location. We'll get it in the system as soon as possible."
      Pony.mail(
        :to => @region.users.collect {|u| u.email},
        :from => 'admin@pinballmap.com',
        :subject => "Someone suggested a new location for #{@region.name}",
        :body => "
          Location Name: #{params['location_name']}\n
          Street: #{params['location_street']}\n
          City: #{params['location_city']}\n
          State: #{params['location_state']}\n
          Zip: #{params['location_zip']}\n
          Phone: #{params['location_phone']}\n
          Website: #{params['location_website']}\n
          Operator: #{params['location_operator']}\n
          Machines: #{params['location_machines']}\n
          Their Name: #{params['submitter_name']}\n
          Their Email: #{params['submitter_email']}\n
        "
      )
    else
      flash.now[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
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
