class MachineCondition < ApplicationRecord
  MAX_HISTORY_SIZE_TO_DISPLAY = 5

  has_paper_trail

  belongs_to :user, optional: true
  belongs_to :location_machine_xref, optional: true, touch: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref
  strip_attributes

  after_create :create_user_submission

  scope :limited, -> { order("created_at DESC").limit(MachineCondition::MAX_HISTORY_SIZE_TO_DISPLAY) }

  def update(options = {})
    if options[:comment] && !options[:comment].blank? && (comment != options[:comment])
      self.comment = options[:comment]

      save
    end
  end

  def create_user_submission
    user_info = user ? user.username : "UNKNOWN USER"
    submission = "#{user_info} commented on #{machine.name_and_year} at #{location.name} in #{location.city}. They said: #{comment}"

    UserSubmission.create(user_name: user&.username, machine_name: machine.name_and_year, location_name: location.name, city_name: location.city, comment: comment, lat: location.lat, lon: location.lon, region_id: location.region_id, location: location, machine: machine, submission_type: UserSubmission::NEW_CONDITION_TYPE, submission: submission, user: user, machine_condition_id: id)
    Rails.logger.info "USER SUBMISSION USER ID #{user&.id} #{submission}"
    User.increment_counter(:num_lmx_comments_left, user&.id)
    location.users_count = UserSubmission.where(location_id: location.id).count("DISTINCT user_id")
    location.save(validate: false)
  end

  def username
    user ? user.username : ""
  end

  def as_json(options = {})
    options[:methods] = [ :username ]
    super
  end
end
