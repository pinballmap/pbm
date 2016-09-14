class User < ActiveRecord::Base
  acts_as_token_authenticatable

  belongs_to :region
  has_many :location_machine_xrefs
  has_many :machine_score_xrefs
  has_many :location_picture_xrefs
  has_many :user_submissions

  validates :username, presence: true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  validates :username, length: { maximum: 15 }

  validate :validate_username

  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable, authentication_keys: [:login]

  attr_accessible :email, :password, :password_confirmation, :remember_me, :region_id, :is_machine_admin, :is_primary_email_contact, :username, :is_disabled, :is_super_admin
  attr_accessor :login

  def role_symbols
    roles = []
    roles << :admin if region_id
    roles << :site_admin if (region_id == Region.find_by_name('portland').id)

    roles
  end

  def validate_username
    return unless User.where(email: username).exists?

    errors.add(:username, :invalid)
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)

    if login
      where(conditions.to_hash).where(['lower(username) = :value OR lower(email) = :value', value: login.downcase]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_hash).first
    end
  end

  def active_for_authentication?
    super && !self.is_disabled?
  end

  def inactive_message
    'Your account is not active. Please contact our support team if you think this was a mistake.'
  end

  def name
    username
  end

  def as_json(_options = {})
    super(only: [:id, :username, :email, :authentication_token])
  end

  def num_machines_added
    UserSubmission.where(user: self, submission_type: UserSubmission::NEW_LMX_TYPE).size
  end

  def num_machines_removed
    UserSubmission.where(user: self, submission_type: UserSubmission::REMOVE_MACHINE_TYPE).size
  end

  def num_locations_edited
    unique_edited_location_ids = edited_location_submissions.map { |s| s.location_id }.uniq!

    unique_edited_location_ids ? unique_edited_location_ids.size : 0
  end

  def num_locations_suggested
    UserSubmission.where('user_id = ? and submission_type = ?', id, UserSubmission::SUGGEST_LOCATION_TYPE).size
  end

  def profile_list_of_high_scores
    msxes = MachineScoreXref.where(user: self).order(:created_at)

    formatted_score_data = []
    msxes.each do |msx|
      formatted_score_data.push(["<span class='score_machine'>#{msx.machine.name}</span>",
        "<span class='score_score'>#{msx.score}</span>",
        "<span class='score_meta'>at </span><span class='score_meta_gen'>#{msx.location.name}</span> <span class='score_meta'> on </span><span class='score_meta_gen'>#{msx.created_at.strftime('%b-%d-%Y')}</span>"].join(''))
    end

    formatted_score_data.join('<br /><br />')
  end

  def profile_list_of_edited_locations(host_with_port)
    submissions = edited_location_submissions

    unique_edited_locations_that_exist = []
    submissions.each do |s|
      next unless s.location_id && Location.exists?(id: s.location_id)

      unique_edited_locations_that_exist.push(s.location)
    end

    unique_edited_locations_that_exist.uniq.map { |l| "<span class='location_edited'><a href='http://#{host_with_port}/#{l.region.name}/?by_location_id=#{l.id}'>#{l.name}</a></span>" }.join('<br />')
  end

  def edited_location_submissions
    UserSubmission.where(
      'location_id is not null and user_id = ? and submission_type in (?,?,?,?,?,?)',
      id,
      UserSubmission::NEW_CONDITION_TYPE,
      UserSubmission::LOCATION_METADATA_TYPE,
      UserSubmission::NEW_LMX_TYPE,
      UserSubmission::REMOVE_MACHINE_TYPE,
      UserSubmission::NEW_SCORE_TYPE,
      UserSubmission::CONFIRM_LOCATION_TYPE
    )
  end
end
