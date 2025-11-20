class User < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  acts_as_token_authenticatable

  belongs_to :region, optional: true
  has_many :location_machine_xrefs
  has_many :machine_score_xrefs
  has_many :location_picture_xrefs
  has_many :user_submissions
  has_many :user_fave_locations

  validates :username, presence: true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /\A[a-zA-Z0-9_\.]*\z/, multiline: true
  validates :username, length: { maximum: 20 }
  validates :flag, inclusion: { in: Country.valid_countries, allow_blank: true, message: "Country ISO not valid." }

  strip_attributes only: %i[username password]

  validate :validate_username

  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable, authentication_keys: [ :login ], confirmation_keys: [ :login ]

  scope :admins, -> { where("region_id is not null") }
  scope :non_admins, -> { where("region_id is null") }

  attr_accessor :login

  def role_symbols
    roles = []
    roles << :admin if region_id
    roles << :site_admin if region_id == Region.find_by_name("portland").id

    roles
  end

  def admin?
    region_id.present?
  end

  def validate_username
    return unless User.where(email: username).exists?

    errors.add(:username, :invalid)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)

    if login
      where(conditions.to_hash).where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_hash).first
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions).where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
    else
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end

  def active_for_authentication?
    super && !is_disabled?
  end

  def inactive_message
    is_disabled? ? :account_inactive : super
  end

  def name
    username
  end

  def num_locations_edited
    unique_edited_location_ids = edited_location_submissions.map(&:location_id).uniq!

    unique_edited_location_ids ? unique_edited_location_ids.size : 0
  end

  def profile_list_of_high_scores
    msx_submissions = UserSubmission.where(user: self, submission_type: UserSubmission::NEW_SCORE_TYPE, deleted_at: nil).order(created_at: "DESC").limit(50)

    high_score_hash = {}
    msx_submissions.each do |msx_sub|
      score = "UNKNOWN"
      if msx_sub.submission =~ /added a high score of (.*) on (.*) at (.*)$/i
        score = $1
        machine_name = $2
        location_name = $3
      end

      next unless score && machine_name && location_name

      high_score_hash[machine_name] = [ location_name, machine_name, number_with_precision(score, precision: 0, delimiter: ","), msx_sub.created_at.strftime("%b %d, %Y") ] if !high_score_hash[machine_name] || high_score_hash[machine_name][2].delete(",").to_i < score.delete(",").to_i
    end

    high_score_hash.values
  end

  def profile_list_of_edited_locations
    user_submissions = UserSubmission.where(user: self).order(created_at: "DESC").includes([ :location ]).limit(50)

    user_submission_locations_hash = {}
    user_submissions.each do |user_sub|
      next if user_sub.location.nil? || user_sub.location_name.nil?

      user_submission_locations_hash[user_sub.location_id] = [ user_sub.location_id, user_sub.location_name ]
    end
    user_submission_locations_hash.values
  end

  def edited_location_submissions
    UserSubmission.where(deleted_at: nil).where(
      "location_id is not null and user_id = ? and submission_type in (?,?,?,?,?,?,?,?)",
      id,
      UserSubmission::NEW_CONDITION_TYPE,
      UserSubmission::LOCATION_METADATA_TYPE,
      UserSubmission::NEW_LMX_TYPE,
      UserSubmission::REMOVE_MACHINE_TYPE,
      UserSubmission::NEW_SCORE_TYPE,
      UserSubmission::CONFIRM_LOCATION_TYPE,
      UserSubmission::IC_TOGGLE_TYPE,
      UserSubmission::NEW_PICTURE_TYPE
    ).order("created_at desc")
  end

  def list_fave_locations
    user_fave_locations.includes([ :location ])
  end

  def num_total_submissions
    user_submissions_count
  end

  # legacy for old versions of app
  def contributor_rank_int
    case user_submissions_count
    when 0...50
      nil
    when 50...250
      5
    when 250...500
      4
    when 500...Float::INFINITY
      3
    end
  end

  # legacy for old versions of app
  def admin_rank_int
    if region_id == 1 || username == "pbm"
      1
    elsif !region_id.blank?
      2
    end
  end

  def as_json(options = {})
    super({ only: [ :id ] }.merge(options))
  end

  def self.send_reset_password_instructions(attributes = {})
    recoverable = find_recoverable_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    recoverable.send_reset_password_instructions if recoverable.persisted?
    recoverable
  end

  def self.find_recoverable_or_initialize_with_errors(required_attributes, attributes, error = :invalid)
    (case_insensitive_keys || []).each { |k| attributes[k].try(:downcase!) }

    attributes = attributes.slice(*required_attributes)
    attributes.delete_if { |_key, value| value.blank? }

    if attributes.key?(:login)
      login = attributes.delete(:login)
      record = find_record(login)
    else
      record = where(attributes).first
    end

    unless record
      record = new

      required_attributes.each do |key|
        value = attributes[key]
        record.send("#{key}=", value)
        record.errors.add(key, value.present? ? error : :blank)
      end
    end
    record
  end

  def self.find_record(login)
    where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
  end
end
