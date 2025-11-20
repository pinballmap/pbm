class Region < ApplicationRecord
  has_paper_trail
  has_many :locations
  has_many :zones
  has_many :users, -> { order "users.id" }
  has_many :events, -> { order "events.id" }
  has_many :operators
  has_many :suggested_locations
  has_many :region_link_xrefs, -> { order "region_link_xrefs.id" }
  has_many :user_submissions
  has_many :location_machine_xrefs, through: :locations
  has_many :machine_score_xrefs, through: :location_machine_xrefs

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

  def n_recent_scores(number_of_scores)
    scores = machine_score_xrefs.sort_by(&:id)
    scores[0, number_of_scores]
  end

  def n_high_rollers(number_of_high_rollers = 10)
    rollers = {}
    @high_rollers = {}

    machine_score_xrefs.each do |msx|
      (rollers[msx.user ? msx.user.username : ""] ||= []) << msx
    end

    rollers.sort { |a, b| b[1].size <=> a[1].size }.each do |roller|
      username = roller[0]
      scores = roller[1]
      scores.sort! { |a, b| b.created_at <=> a.created_at }

      @high_rollers[username] = scores unless @high_rollers.size == number_of_high_rollers
    end

    @high_rollers
  end

  before_save do
    Status.where(status_type: "regions").update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: "regions").update({ updated_at: Time.current })
  end

  def all_admin_email_addresses
    if users.empty?
      [ "email_not_found@noemailfound.noemail" ]
    else
      users.map(&:email).sort
    end
  end

  def primary_email_contact
    return "email_not_found@noemailfound.noemail" if users.empty?

    users.each do |u|
      return u.email if u.is_primary_email_contact
    end

    users.first.email
  end

  def locations_count
    Location.count_by_sql "select count(*) from locations where region_id=#{id}"
  end

  def machines_count
    LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{id}"
  end

  def available_search_sections
    sections = %w[location city machine type]

    sections.push("operator") if operators.present? || Operator.where(region_id: nil).exists?

    sections.push("zone") unless zones.empty?

    "[" + sections.map { |s| "'" + s + "'" }.join(", ") + "]"
  end

  def filtered_region_links
    links = {}
    region_link_xrefs.each do |rlx|
      (links[rlx.category && !rlx.category.blank? ? rlx.category : "Links"] ||= []) << rlx
    end

    links
  end

  def html_motd
    message = motd.to_s.gsub(%r{(\b(((https?|ftp|file|):\/\/)|www[.])[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])}i) { |s| "<a href =#{s} target=_blank>#{s}</a>" }
    message.html_safe
  end

  def lat_and_lon
    [ lat, lon ].join(", ")
  end

  def self.generate_daily_digest_global_comments_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::NEW_CONDITION_TYPE).collect(&:submission) }
  end

  def generate_daily_digest_comments_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_day, end_of_day, UserSubmission::NEW_CONDITION_TYPE, self).collect(&:submission) }
  end

  def self.generate_daily_digest_global_picture_added_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::NEW_PICTURE_TYPE).collect(&:submission) }
  end

  def self.generate_daily_digest_global_score_added_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::NEW_SCORE_TYPE).collect(&:submission) }
  end

  def self.generate_daily_digest_global_removal_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_day, end_of_day, UserSubmission::REMOVE_MACHINE_TYPE).collect(&:submission) }
  end

  def generate_daily_digest_removal_email_body
    start_of_day = (Time.now - 1.day).beginning_of_day
    end_of_day = (Time.now - 1.day).end_of_day

    { submissions: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_day, end_of_day, UserSubmission::REMOVE_MACHINE_TYPE, self).collect(&:submission) }
  end

  def self.generate_weekly_global_email_body
    start_of_week = (Time.now - 1.week).beginning_of_day
    end_of_week = Time.now.end_of_day

    { machines_count: LocationMachineXref.all.count,
      locations_count: Location.all.count,

      contact_messages_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::CONTACT_US_TYPE).count,

      machineless_locations: Location.where(machine_count: 0).each.map { |ml| ml.name + " (#{ml.city}, #{ml.state})" },

      suggested_locations_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::SUGGEST_LOCATION_TYPE).count,

      locations_added_count: Location.where("created_at is not null and created_at > ? and created_at < ?", start_of_week, end_of_week).count,

      locations_deleted_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::DELETE_LOCATION_TYPE).count,

      machine_comments_count: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_CONDITION_TYPE).count,

      machines_added_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_LMX_TYPE).count,

      machines_removed_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::REMOVE_MACHINE_TYPE).count,

      pictures_added_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_PICTURE_TYPE).count,

      scores_added_count: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_SCORE_TYPE).count,

      scores_deleted_count: UserSubmission.where.not(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_SCORE_TYPE).count,

      machine_comments_deleted_count: UserSubmission.where.not(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ?", start_of_week, end_of_week, UserSubmission::NEW_CONDITION_TYPE).count
    }
  end

  def generate_weekly_admin_email_body
    start_of_week = (Time.now - 1.week).beginning_of_day
    end_of_week = Time.now.end_of_day

    { full_name: full_name,
      machines_count: machines_count,
      locations_count: locations_count,

      events_count: Event.where("region_id = ?", self).count,

      contact_messages_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::CONTACT_US_TYPE, self).count,

      machineless_locations: Location.where(region_id: self, machine_count: 0).each.map { |ml| ml.name + " (#{ml.city}, #{ml.state})" },

      suggested_locations: SuggestedLocation.where(region_id: self).each.map(&:name),

      suggested_locations_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::SUGGEST_LOCATION_TYPE, self).count,

      locations_added_count: Location.where("created_at is not null and created_at > ? and created_at < ? and region_id = ?", start_of_week, end_of_week, self).count,

      locations_deleted_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::DELETE_LOCATION_TYPE, self).count,

      machine_comments_count: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::NEW_CONDITION_TYPE, self).count,

      machines_added_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::NEW_LMX_TYPE, self).count,

      machines_removed_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::REMOVE_MACHINE_TYPE, self).count,

      pictures_added_count: UserSubmission.where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::NEW_PICTURE_TYPE, self).count,

      scores_added_count: UserSubmission.where(deleted_at: nil).where("created_at is not null and created_at > ? and created_at < ? and submission_type = ? and region_id = ?", start_of_week, end_of_week, UserSubmission::NEW_SCORE_TYPE, self).count
    }
  end

  def self.delete_empty_regionless_locations
    Location.where("region_id is null").each do |l|
      l.destroy if l.location_machine_xrefs.count.zero?
    end
  end

  def delete_all_empty_locations
    return unless should_auto_delete_empty_locations

    locations.each do |l|
      l.destroy if l.location_machine_xrefs.count.zero?
    end
  end

  def self.delete_all_regionless_events
    Event.where("region_id is null").each do |e|
      e.destroy
    end
  end

  def delete_all_expired_events
    events.each do |e|
      if e.start_date.blank? && !e.end_date.blank?
        e.destroy
      elsif !e.start_date.blank? && e.end_date.blank?
        e.destroy if e.start_date < 1.week.ago
      elsif !e.end_date.blank?
        e.destroy if e.end_date < 1.week.ago
      end
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
