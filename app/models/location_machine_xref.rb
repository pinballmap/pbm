class LocationMachineXref < ApplicationRecord
  belongs_to :location, optional: true, counter_cache: :machine_count
  belongs_to :machine, optional: true
  belongs_to :user, optional: true
  has_many :machine_score_xrefs, -> { order "created_at desc" }
  has_many :machine_conditions, -> { order "created_at desc" }

  default_scope { where(deleted_at: nil) }

  after_create :update_location, :create_user_submission

  scope :region, lambda { |name|
    r = Region.find_by_name(name.downcase)

    return unless r

    joins(:location).where("locations.region_id = ?", r.id)
  }

  def haml_object_ref
    "lmx"
  end

  def add_host_info_to_subject(subject, host)
    server_name = host&.match?(/pbmstaging/) ? "(STAGING) " : ""

    server_name + subject
  end

  def update_condition(condition, options = {})
    return if condition == machine_conditions.first&.comment
    return if condition.blank?

    self.user_id = options[:user_id]

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = options[:user_id]
    location.save(validate: false)

    save

    MachineCondition.create(comment: condition, location_machine_xref: self, user_id: location.last_updated_by_user_id)
  end

  def as_json(options = {})
    h = super(options)
    h[:machine_conditions] = machine_conditions.first(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)

    h
  end

  def sorted_machine_conditions
    machine_conditions.limited.includes([ :user ])
  end

  def sorted_machine_scores
    machine_score_xrefs.limited.includes([ :user ])
  end

  def update_location
    location.date_last_updated = Date.today
    if user
      location.last_updated_by_user_id = user.id
    elsif location.last_updated_by_user_id
      location.last_updated_by_user_id = location.last_updated_by_user_id
    else
      location.last_updated_by_user_id = nil
    end
    location.save(validate: false)
  end

  def destroy(options = {}, force: false)
    user = nil
    user = User.find(options[:user_id]) if options[:user_id]
    submission = "#{machine.name_and_year} was removed from #{location.name} in #{location.city}#{user.nil? ? '' : ' by ' + user.name}"

    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: submission, user: user)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"

    if location.location_machine_xrefs.where(ic_enabled: true).empty?
      location.ic_active = false
    end

    Location.decrement_counter(:machine_count, location.id) unless force
    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user.nil? ? nil : user.id
    location.save(validate: false)
    location
    User.increment_counter(:num_machines_removed, user&.id)
    location.users_count = UserSubmission.where(location_id: location.id).count("DISTINCT user_id")
    location.save(validate: false)

    super() if force
  end

  def create_user_submission
    submission = "#{machine.name_and_year} was added to #{location.name} in #{location.city}#{user.nil? ? '' : ' by ' + user.name}"
    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_LMX_TYPE, submission: submission, user: user)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
    User.increment_counter(:num_machines_added, user&.id)
    location.users_count = UserSubmission.where(location_id: location.id).count("DISTINCT user_id")
    location.save(validate: false)
  end

  def create_ic_user_submission(user)
    submission = "Insider Connected toggled on #{machine.name_and_year} at #{location.name} in #{location.city} by #{user.username}"
    UserSubmission.create(user_name: user.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::IC_TOGGLE_TYPE, submission: submission, user: user)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
    location.users_count = UserSubmission.where(location_id: location.id).count("DISTINCT user_id")
    location.save(validate: false)
  end

  def create_ic_user_submission!(user)
    raise ActiveRecord::RecordInvalid unless create_ic_user_submission(user)
  end

  def last_updated_by_username
    user ? user.username : ""
  end
end
