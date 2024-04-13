class LocationMachineXref < ApplicationRecord
  include Rakismet::Model

  rakismet_attrs content: :condition

  belongs_to :location, optional: true
  belongs_to :machine, optional: true
  belongs_to :user, optional: true
  has_many :machine_score_xrefs
  has_many :machine_conditions, (-> { order 'created_at desc' })

  after_create :update_location, :create_user_submission

  scope :region, (lambda { |name|
    r = Region.find_by_name(name.downcase)

    return unless r

    joins(:location).where('locations.region_id = ?', r.id)
  })

  def haml_object_ref
    'lmx'
  end

  def add_host_info_to_subject(subject, host)
    server_name = host&.match?(/pbmstaging/) ? '(STAGING) ' : ''

    server_name + subject
  end

  def update_condition(condition, options = {})
    return if condition == self.condition
    return if condition.blank?

    self.condition = condition
    self.condition_date = Date.today
    self.user_id = options[:user_id]

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = options[:user_id]
    location.save(validate: false)

    save

    MachineCondition.create(comment: condition, location_machine_xref: self, user_id: location.last_updated_by_user_id)

    return if condition.nil? || condition.blank? || location.region_id.blank?

    if location.region&.send_digest_comment_emails?
      user_info = location.last_updated_by_user ? " by #{location.last_updated_by_user.username} (#{location.last_updated_by_user.email})" : ''

      AdminMailer.with(to_users: location.region.users.map(&:email), subject: add_host_info_to_subject('Pinball Map - New machine condition'), condition: condition, machine_name: machine.name, location_name: location.name, location_city: location.city, location_region: location.region.name, remote_ip: request.remote_ip, headers: request.headers['AppVersion'], user_agent: request.user_agent, user_info: user_info).new_machine_condition.deliver_now
    end
  end

  def as_json(options = {})
    h = super(options)
    h[:machine_conditions] = machine_conditions.first(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY)

    h
  end

  def sorted_machine_conditions
    machine_conditions.limited.includes([:user])
  end

  def update_location
    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user ? user.id : nil
    location.save(validate: false)
  end

  def destroy(options = {})
    if location.region&.should_email_machine_removal && !location.region&.send_digest_removal_emails
      user_info = nil
      if options[:user_id]
        user = User.find(options[:user_id])
        user_info = " by #{user.username} (#{user.email})"
      end

      AdminMailer.with(to_users: location.region.users.map(&:email), subject: add_host_info_to_subject('Pinball Map - Machine removed'), machine_name: machine.name, location_name: location.name, location_city: location.city, location_region: location.region.name, remote_ip: options[:remote_ip], headers: request.headers['AppVersion'], user_agent: options[:user_agent], user_info: user_info).machine_removal.deliver_now
    end

    user = nil
    user = User.find(options[:user_id]) if options[:user_id]

    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: "#{machine.name_and_year} was removed from #{location.name} in #{location.city}#{user.nil? ? '' : ' by ' + user.name}", user: user)

    location.date_last_updated = Date.today
    location.last_updated_by_user_id = user.nil? ? nil : user.id
    location.save(validate: false)
    location

    super()
  end

  def create_user_submission
    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_LMX_TYPE, submission: "#{machine.name_and_year} was added to #{location.name} in #{location.city}#{user.nil? ? '' : ' by ' + user.name}", user: user)
  end

  def create_ic_user_submission(user)
    UserSubmission.create(user_name: user.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::IC_TOGGLE_TYPE, submission: "Insider Connected toggled on #{machine.name_and_year} at #{location.name} in #{location.city} by #{user.username}", user: user)
  end

  def create_ic_user_submission!(user)
    raise ActiveRecord::RecordInvalid unless create_ic_user_submission(user)
  end

  def last_updated_by_username
    user ? user.username : ''
  end
end
