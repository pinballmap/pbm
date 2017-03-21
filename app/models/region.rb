class Region < ActiveRecord::Base
  has_many :locations
  has_many :zones
  has_many :users, -> { order 'users.id' }
  has_many :events, -> { order 'events.id' }
  has_many :operators
  has_many :region_link_xrefs, -> { order 'region_link_xrefs.id' }
  has_many :user_submissions
  has_many :location_machine_xrefs, through: :locations

  attr_accessible :name, :full_name, :motd, :lat, :lon, :n_search_no, :default_search_type, :should_email_machine_removal

  geocoded_by :lat_and_lon, latitude: :lat, longitude: :lon

  def machines
    machines = {}
    location_machine_xrefs.includes(:machine).each do |lmx|
      machines[lmx.machine.id] = lmx.machine
    end

    machines.values.sort_by(&:name)
  end

  def machine_score_xrefs
    machine_score_xrefs = []

    location_machine_xrefs.includes(:machine_score_xrefs, :location, :machine).each do |lmx|
      machine_score_xrefs += lmx.machine_score_xrefs if lmx.machine_score_xrefs
    end

    machine_score_xrefs
  end

  def n_recent_scores(n)
    scores = machine_score_xrefs.sort_by(&:id)
    scores[0, n]
  end

  def n_high_rollers(n = 10)
    rollers = {}
    @high_rollers = {}

    machine_score_xrefs.each do |msx|
      (rollers[msx.user ? msx.user.username : ''] ||= []) << msx
    end

    rollers.sort { |a, b| b[1].size <=> a[1].size }.each do |roller|
      username = roller[0]
      scores = roller[1]
      scores.sort! { |a, b| b.created_at <=> a.created_at }

      @high_rollers[username] = scores unless @high_rollers.size == n
    end

    @high_rollers
  end

  def all_admin_email_addresses
    if users.empty?
      ['email_not_found@noemailfound.noemail']
    else
      users.map(&:email).sort
    end
  end

  def primary_email_contact
    if users.empty?
      'email_not_found@noemailfound.noemail'
    elsif users.where(is_primary_email_contact: true).any?
      users
        .where(is_primary_email_contact: true)
        .first
        .email
    else
      users
        .first
        .email
    end
  end

  def machineless_locations
    locations.select { |location| location.machines.empty? }
  end

  def locations_count
    Location.count_by_sql "select count(*) from locations where region_id=#{id}"
  end

  def machines_count
    LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{id}"
  end

  def available_search_sections
    sections = %w(location city machine type)

    sections.push('operator') unless operators.empty?

    sections.push('zone') unless zones.empty?

    '[' + sections.map { |s| "'" + s + "'" }.join(', ') + ']'
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\" id=\"infowindow_#{id}\">"
    content += "<div class=\"gm_region_name\"><a href=\"#{name}\">#{full_name.gsub("'", "\\\\'")}</a></div>"
    content += '<hr />'
    content += "<div class=\"gm_location_count\">#{locations.size} Locations</div>"
    content += "<div class=\"gm_machine_count\">#{location_machine_xrefs.size} Machines</div>"
    content += "</div>'"

    content.html_safe
  end

  def filtered_region_links
    links = {}
    region_link_xrefs.each do |rlx|
      (links[rlx.category && !rlx.category.blank? ? rlx.category : 'Links'] ||= []) << rlx
    end

    links
  end

  def lat_and_lon
    [lat, lon].join(', ')
  end

  def generate_weekly_admin_email_body
    start_of_week = (DateTime.now - 1.week).beginning_of_day
    end_of_week = DateTime.now.end_of_day

    <<HERE
Here's an overview of your pinball map region! Thanks for keeping your region updated! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact pinballmap@posteo.org

#{full_name} Weekly Overview

List of Empty Locations:
#{machineless_locations.each.map { |ml| ml.name + " (#{ml.city}, #{ml.state})" }.sort.join("\n")}

#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::SUGGEST_LOCATION_TYPE }.count} Location(s) submitted to you this week
#{locations.select { |l| !l.created_at.nil? && l.created_at.between?(start_of_week, end_of_week) }.count} Location(s) added by you this week
#{location_machine_xrefs.select { |lmx| !lmx.created_at.nil? && lmx.created_at.between?(start_of_week, end_of_week) }.count} machine(s) added by users this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }.count} machine(s) removed by users this week
#{full_name} is listing #{machines_count} machines and #{locations_count} locations
#{events.select(&:active?).count} event(s) listed
#{events.select { |e| !e.created_at.nil? && e.created_at.between?(start_of_week, end_of_week) && (e.end_date.nil? || e.end_date >= Date.today) }.count} event(s) added this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::CONTACT_US_TYPE }.count} "contact us" message(s) sent to you
HERE
  end

  def delete_all_empty_locations
    return unless should_auto_delete_empty_locations

    locations.each do |l|
      l.destroy if l.location_machine_xrefs.count.zero?
    end
  end

  def move_to_new_region(new_region)
    locations.each do |l|
      l.region = new_region
      l.save
    end

    events.each do |e|
      e.region = new_region
      e.save
    end

    operators.each do |o|
      o.region = new_region
      o.save
    end

    region_link_xrefs.each do |rlx|
      rlx.region = new_region
      rlx.save
    end

    users.each do |u|
      u.region = new_region
      u.save
    end

    zones.each do |z|
      z.region = new_region
      z.save
    end

    user_submissions.each do |us|
      us.region = new_region
      us.save
    end
  end
end
