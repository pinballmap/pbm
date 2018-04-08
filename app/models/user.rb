class User < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  acts_as_token_authenticatable

  belongs_to :region, optional: true
  has_many :location_machine_xrefs
  has_many :machine_score_xrefs
  has_many :location_picture_xrefs
  has_many :user_submissions

  validates :username, presence: true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  validates :username, length: { maximum: 15 }

  validate :validate_username

  devise :database_authenticatable, :confirmable, :registerable, :recoverable, :rememberable, :trackable, :validatable, authentication_keys: [:login]

  attr_accessor :login

  def role_symbols
    roles = []
    roles << :admin if region_id
    roles << :site_admin if region_id == Region.find_by_name('portland').id

    roles
  end

  def admin?
    defined? region_id
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
    super && !is_disabled?
  end

  def name
    username
  end

  def num_machines_added
    UserSubmission.where(user: self, submission_type: UserSubmission::NEW_LMX_TYPE).size
  end

  def num_machines_removed
    UserSubmission.where(user: self, submission_type: UserSubmission::REMOVE_MACHINE_TYPE).size
  end

  def num_locations_edited
    unique_edited_location_ids = edited_location_submissions.map(&:location_id).uniq!

    unique_edited_location_ids ? unique_edited_location_ids.size : 0
  end

  def num_locations_suggested
    UserSubmission.where('user_id = ? and submission_type = ?', id, UserSubmission::SUGGEST_LOCATION_TYPE).size
  end

  def num_lmx_comments_left
    UserSubmission.where('user_id = ? and submission_type = ?', id, UserSubmission::NEW_CONDITION_TYPE).size
  end

  def profile_list_of_high_scores
    msx_submissions = UserSubmission.where(user: self, submission_type: UserSubmission::NEW_SCORE_TYPE).order(:created_at => "DESC")

    formatted_score_data = []
    msx_submissions.each do |msx_sub|
      score = 'UNKNOWN'
      if msx_sub.submission =~ /added a score of (.*) for (.*) to (.*)$/i
        score = $1
        machine_name = $2
        location_name = $3
      end

      next unless score && machine_name && location_name

      formatted_score_data.push([location_name, machine_name, number_with_precision(score, precision: 0, delimiter: ','), msx_sub.created_at.strftime('%b-%d-%Y')])
    end

    formatted_score_data
  end

  def profile_list_of_edited_locations
    submissions = edited_location_submissions
    submissions = submissions.select { |s| s.location_id && Location.exists?(id: s.location_id) }
    submissions = submissions.reverse.uniq(&:location_id)
    submissions = submissions.reverse

    submissions.map { |s| [s.location_id, s.location.name, s.location.region_id] }
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
    ).order('created_at desc')
  end

  def as_json(options = {})
    super({ only: [:id] }.merge(options))
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

    if attributes.size == required_attributes.size
      if attributes.key?(:login)
        login = attributes.delete(:login)
        record = find_record(login)
      else
        record = where(attributes).first
      end
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
    where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
  end
end
