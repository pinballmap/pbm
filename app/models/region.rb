class Region < ApplicationRecord
  has_many :locations
  has_many :zones
  has_many :users, (-> { order 'users.id' })
  has_many :events, (-> { order 'events.id' })
  has_many :operators
  has_many :suggested_locations
  has_many :region_link_xrefs, (-> { order 'region_link_xrefs.id' })
  has_many :user_submissions
  has_many :location_machine_xrefs, through: :locations
  has_many :machine_score_xrefs, through: :location_machine_xrefs

  geocoded_by :lat_and_lon, latitude: :lat, longitude: :lon

  def self.machine_and_location_count_by_region
    records_array = ActiveRecord::Base.connection.execute(<<HERE)
select
  r.id as region_id,
  count(distinct l.id) as locations_count,
  count(distinct x.id) as machines_count
from
  regions r
  left outer join locations l on l.region_id = r.id
  left outer join location_machine_xrefs x on x.location_id = l.id
group by
  1
HERE

    machine_and_location_count_by_region = {}
    records_array.each do |r|
      machine_and_location_count_by_region[r['region_id']] = {}
      machine_and_location_count_by_region[r['region_id']]['locations_count'] = r['locations_count']
      machine_and_location_count_by_region[r['region_id']]['machines_count'] = r['machines_count']
    end

    machine_and_location_count_by_region
  end

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

  def n_recent_scores(number_of_scores)
    scores = machine_score_xrefs.sort_by(&:id)
    scores[0, number_of_scores]
  end

  def n_high_rollers(number_of_high_rollers = 10)
    rollers = {}
    @high_rollers = {}

    machine_score_xrefs.each do |msx|
      (rollers[msx.user ? msx.user.username : ''] ||= []) << msx
    end

    rollers.sort { |a, b| b[1].size <=> a[1].size }.each do |roller|
      username = roller[0]
      scores = roller[1]
      scores.sort! { |a, b| b.created_at <=> a.created_at }

      @high_rollers[username] = scores unless @high_rollers.size == number_of_high_rollers
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
    return 'email_not_found@noemailfound.noemail' if users.empty?

    users.each do |u|
      return u.email if u.is_primary_email_contact
    end

    users.first.email
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
    sections = %w[location city machine type]

    sections.push('operator') if operators.present? || Operator.where(region_id: nil).exists?

    sections.push('zone') unless zones.empty?

    '[' + sections.map { |s| "'" + s + "'" }.join(', ') + ']'
  end

  def content_for_infowindow(locations_count, machines_count)
    content = "'<div class=\"infowindow\" id=\"infowindow_#{id}\">"
    content += "<div class=\"gm_region_name\"><a href=\"#{name}\">#{full_name.gsub("'", "\\\\'")}</a></div>"
    content += '<hr />'
    content += "<div class=\"gm_location_count\">#{locations_count} Locations</div>"
    content += "<div class=\"gm_machine_count\">#{machines_count} Machines</div>"
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

  def html_motd
    message = motd.to_s.gsub(%r{(\b(((https?|ftp|file|):\/\/)|www[.])[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])}i) { |s| "<a href =#{s} target=_blank>#{s}</a>" }
    message.html_safe
  end

  def lat_and_lon
    [lat, lon].join(', ')
  end

  def self.generate_daily_digest_regionless_comments_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    submissions = UserSubmission.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_day, end_of_day) && us.submission_type == UserSubmission::NEW_CONDITION_TYPE && us.region_id.nil? }.collect(&:submission).sort.join("\n\n")

    return nil if submissions.nil? || submissions.empty?

    <<HERE
Here is a list of all the comments that were placed in regionless locations on #{(Time.now - 1.day).strftime('%m/%d/%Y')}.

REGIONLESS Daily Comments

#{submissions}
HERE
  end

  def generate_daily_digest_comments_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    submissions = user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_day, end_of_day) && us.submission_type == UserSubmission::NEW_CONDITION_TYPE }.collect(&:submission).sort.join("\n\n")

    return nil if submissions.nil? || submissions.empty?

    <<HERE
Here is a list of all the comments that were placed in your region on #{(Time.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact pinballmap@fastmail.com

#{full_name} Daily Comments

#{submissions}
HERE
  end

  def self.generate_daily_digest_regionless_removals_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    submissions = UserSubmission.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_day, end_of_day) && us.submission_type == UserSubmission::REMOVE_MACHINE_TYPE && us.region_id.nil? }.collect(&:submission).sort.join("\n\n")

    return nil if submissions.nil? || submissions.empty?

    <<HERE
Here is a list of all the machines that were removed from regionless locations on #{(Time.now - 1.day).strftime('%m/%d/%Y')}.

REGIONLESS Daily Machine Removals

#{submissions}
HERE
  end

  def generate_daily_digest_removals_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    submissions = user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_day, end_of_day) && us.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }.collect(&:submission).sort.join("\n\n")

    return nil if submissions.nil? || submissions.empty?

    <<HERE
Here is a list of all the machines that were removed from your region on #{(Time.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact pinballmap@fastmail.com

#{full_name} Daily Machine Removals

#{submissions}
HERE
  end

  def self.generate_weekly_regionless_email_body
    start_of_week = (Time.now - 1.week).beginning_of_day
    end_of_week = Time.now.end_of_day

    regionless_locations = Location.where('region_id is null')
    regionless_user_submissions = UserSubmission.where('region_id is null')
    regionless_machine_count = LocationMachineXref.count_by_sql('select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id is null')

    regionless_machines_added_by_users_this_week = 0
    regionless_locations.each do |l|
      regionless_machines_added_by_users_this_week += l.location_machine_xrefs.select { |lmx| !lmx.created_at.nil? && lmx.created_at.between?(start_of_week, end_of_week) }.count
    end

    <<HERE
Here is an overview of regionless locations! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact pinballmap@fastmail.com

Regionless Weekly Overview

List of Empty Locations:
#{regionless_locations.select { |location| location.machines.empty? }.each.map { |ml| ml.name + " (#{ml.city}, #{ml.state})" }.sort.join("\n")}

List of Suggested Locations:
#{SuggestedLocation.where('region_id is null').each.map(&:name).sort.join("\n")}

#{UserSubmission.where('region_id is null').select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::SUGGEST_LOCATION_TYPE }.count} Location(s) submitted to you this week
#{regionless_locations.select { |l| !l.created_at.nil? && l.created_at.between?(start_of_week, end_of_week) }.count} Location(s) added by you this week
#{regionless_user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::DELETE_LOCATION_TYPE }.count} Location(s) deleted this week
#{regionless_user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::NEW_CONDITION_TYPE }.count} machine comment(s) by users this week
#{regionless_machines_added_by_users_this_week} machine(s) added by users this week
#{regionless_user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }.count} machine(s) removed by users this week
REGIONLESS is listing #{regionless_machine_count} machines and #{regionless_locations.count} locations
HERE
  end

  def generate_weekly_admin_email_body
    start_of_week = (Time.now - 1.week).beginning_of_day
    end_of_week = Time.now.end_of_day

    <<HERE
Here is an overview of your pinball map region! Thanks for keeping your region updated! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact pinballmap@fastmail.com

#{full_name} Weekly Overview

List of Empty Locations:
#{machineless_locations.each.map { |ml| ml.name + " (#{ml.city}, #{ml.state})" }.sort.join("\n")}

List of Suggested Locations:
#{suggested_locations.each.map(&:name).sort.join("\n")}

#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::SUGGEST_LOCATION_TYPE }.count} Location(s) submitted to you this week
#{locations.select { |l| !l.created_at.nil? && l.created_at.between?(start_of_week, end_of_week) }.count} Location(s) added by you this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::DELETE_LOCATION_TYPE }.count} Location(s) deleted this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::NEW_CONDITION_TYPE }.count} machine comment(s) by users this week
#{location_machine_xrefs.select { |lmx| !lmx.created_at.nil? && lmx.created_at.between?(start_of_week, end_of_week) }.count} machine(s) added by users this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::REMOVE_MACHINE_TYPE }.count} machine(s) removed by users this week
#{full_name} is listing #{machines_count} machines and #{locations_count} locations
#{events.select(&:active?).count} event(s) listed
#{events.select { |e| !e.created_at.nil? && e.created_at.between?(start_of_week, end_of_week) && (e.end_date.nil? || e.end_date >= Date.today) }.count} event(s) added this week
#{user_submissions.select { |us| !us.created_at.nil? && us.created_at.between?(start_of_week, end_of_week) && us.submission_type == UserSubmission::CONTACT_US_TYPE }.count} "contact us" message(s) sent to you
HERE
  end

  def self.delete_empty_regionless_locations
    Location.where('region_id is null').each do |l|
      l.destroy if l.location_machine_xrefs.count.zero?
    end
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

  def random_location_id
    offset = rand(locations.count)
    locations.offset(offset).first.id
  end
end
