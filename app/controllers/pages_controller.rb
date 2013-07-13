require 'pony'

class PagesController < ApplicationController
  def region
    @locations = Location.where('region_id = ?', @region.id)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    cities = Hash.new
    location_types = Hash.new

    @locations.each do |l|
      location_copy = l.clone
      if (location_copy.location_type_id)
        location_types[location_copy.location_type_id] = location_copy
      end

      cities[l.city] = location_copy

      location_copy = nil
    end

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => location_types.values.collect { |l| l.location_type }.sort {|a,b| a.name <=> b.name},
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => @locations.sort_by(&:name),
        'autocomplete' => 1,
      },
      'machine' => {
        'id'   => 'id',
        'name' => 'name_and_year',
        'search_collection' => @region.machines.sort_by(&:massaged_name),
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
        'search_collection' => cities.values.sort_by(&:city),
      }
    }

    render "#{@region.name}/region" if (lookup_context.find_all("#{@region.name}/region").any?)
  end

  def contact_sent
      return unless params['contact_msg']

      if (verify_recaptcha)
        flash.now[:alert] = "Thanks for contacting us!"
        Pony.mail(
          :to => @region.users.collect {|u| u.email},
          :from => 'admin@pinballmap.com',
          :subject => "Message from #{@region.full_name} pinball map",
          :body => [params['contact_name'], params['contact_email'], params['contact_msg']].join("\n")
        )
      else
        flash.now[:alert] = "Your captcha entering skills have failed you. Please go back and try again."
      end
  end

  def about
    @links = Hash.new
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.category || 'Uncategorized'] ||= []) << rlx
    end

    render "#{@region.name}/about" if (lookup_context.find_all("#{@region.name}/about").any?)
  end

  def links
    redirect_to about_path
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    if (verify_recaptcha)
      flash.now[:alert] = "Thanks for entering that location. We'll get it in the system as soon as possible."

      Pony.mail(
        :to => @region.users.collect {|u| u.email},
        :bcc => User.all.select {|u| u.is_super_admin }.collect {|u| u.email},
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

  def robots
    robots = File.read(Rails.root + 'public/robots.txt')
    render :text => robots, :layout => false, :content_type => "text/plain"
  end

  def apps
  end

  def app_support
  end

  def contact
    redirect_to about_path
  end

  def home
    if (ENV['TWITTER_CONSUMER_KEY'] && ENV['TWITTER_CONSUMER_SECRET'] && ENV['TWITTER_OAUTH_TOKEN_SECRET'] && ENV['TWITTER_OAUTH_TOKEN'])
      @tweets = Twitter.user_timeline("pinballmapcom", :count => 5)
    else
      @tweets = []
    end
  end
end
