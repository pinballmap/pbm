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
    'Your account has been disabled. Please contact our support team if you think this was a mistake.'
  end

  def name
    username
  end
end
