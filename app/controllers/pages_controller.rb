require 'pony'

class PagesController < ApplicationController
  def region
    @locations = Location.where('region_id = ?', @region.id)
    @location_count = @locations.count
    @lmx_count = @region.machines_count

    cities = {}
    location_types = {}

    @locations.each do |l|
      location_types[l.location_type_id] = l if l.location_type_id

      cities[l.city] = l
    end

    @search_options = {
      'type' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => location_types.values.map { |l| l.location_type }.sort { |a, b| a.name <=> b.name }
      },
      'location' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => @locations.sort_by(&:massaged_name),
        'autocomplete' => 1
      },
      'machine' => {
        'id'   => 'id',
        'name' => 'name_and_year',
        'search_collection' => @region.machines.sort_by(&:massaged_name),
        'autocomplete' => 1
      },
      'zone' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Zone.where('region_id = ?', @region.id).order('name')
      },
      'operator' => {
        'id'   => 'id',
        'name' => 'name',
        'search_collection' => Operator.where('operators.region_id = ?', @region.id).joins(:locations).group('operators.id').order('name')
      },
      'city' => {
        'id'   => 'city',
        'name' => 'city',
        'search_collection' => cities.values.sort_by(&:city)
      }
    }

    render "#{@region.name}/region" if lookup_context.find_all("#{@region.name}/region").any?
  end

  def contact_sent
    return unless params['contact_msg']

    if verify_recaptcha
      flash.now[:alert] = 'Thanks for contacting us!'
      user = (Authorization.current_user.nil? || Authorization.current_user.is_a?(Authorization::AnonymousUser)) ? nil : Authorization.current_user
      send_admin_notification({ email: params['contact_email'], name: params['contact_name'], message: params['contact_msg'] }, @region, user)
    else
      flash.now[:alert] = 'Your captcha entering skills have failed you. Please go back and try again.'
    end
  end

  def about
    @links = {}
    @region.region_link_xrefs.each do |rlx|
      (@links[(rlx.category && !rlx.category.blank?) ? rlx.category : 'Links'] ||= []) << rlx
    end

    @top_machines = LocationMachineXref
      .region(@region.name)
      .select('machine_id, count(*) as machine_count')
      .group(:machine_id)
      .order('machine_count desc')
      .limit(10)

    render "#{@region.name}/about" if lookup_context.find_all("#{@region.name}/about").any?
  end

  def links
    redirect_to about_path
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    if verify_recaptcha
      if params['location_machines'].match('http://')
        flash.now[:alert] = "This sort of seems like you are sending us spam. If that's not the case, please contact us via the about page."
      else
        flash.now[:alert] = "Thanks for entering that location. We'll get it in the system as soon as possible."

        user = (Authorization.current_user.nil? || Authorization.current_user.is_a?(Authorization::AnonymousUser)) ? nil : Authorization.current_user
        send_new_location_notification(params, @region, user)
      end
    else
      flash.now[:alert] = 'Your captcha entering skills have failed you. Please go back and try again.'
    end
  end

  def suggest_new_location
    @states = Location.where(['region_id = ?', @region.id]).map { |r| r.state }.uniq.sort
  end

  def robots
    robots = File.read(Rails.root + 'public/robots.txt')
    render text: robots, layout: false, content_type: 'text/plain'
  end

  def apps
  end

  def app_support
  end

  def privacy
  end

  def store
  end

  def faq
  end

  def donate
  end

  def contact
    redirect_to about_path
  end

  def home
    if ENV['TWITTER_CONSUMER_KEY'] && ENV['TWITTER_CONSUMER_SECRET'] && ENV['TWITTER_OAUTH_TOKEN_SECRET'] && ENV['TWITTER_OAUTH_TOKEN']
      begin
        client = Twitter::REST::Client.new do |config|
          config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
          config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
          config.access_token = ENV['TWITTER_OAUTH_TOKEN']
          config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
        end
        @tweets = client.user_timeline('pinballmapcom', count: 5)
      rescue Twitter::Error
        @tweets = []
      end
    else
      @tweets = []
    end

    @all_regions = Region.order('full_name')
    @region_data = regions_javascript_data(@all_regions)
  end

  def regions_javascript_data(regions)
    ids = []
    lats = []
    lons = []
    contents = []

    regions.each do |r|
      ids      << r.id
      lats     << r.lat
      lons     << r.lon
      contents << r.content_for_infowindow
    end

    [ids, lats, lons, contents]
  end
end
