class ApiToken < ApplicationRecord
  DISABLED_REASONS = %w[regenerated revoked denied account_deleted].freeze

  belongs_to :user
  belongs_to :approved_by, class_name: "User", foreign_key: "approved_by_user_id", optional: true
  belongs_to :disabled_by, class_name: "User", foreign_key: "disabled_by_user_id", optional: true

  validates :requested_use, presence: true
  validates :token, uniqueness: true, allow_nil: true
  validates :disabled_reason, inclusion: { in: DISABLED_REASONS }, allow_nil: true
  validate :token_present_when_approved

  scope :pending, -> { where(approved_at: nil, disabled_at: nil) }
  scope :active, -> { where(disabled_at: nil).where.not(approved_at: nil) }
  scope :denied, -> { where(approved_at: nil).where.not(disabled_at: nil) }
  scope :revoked, -> { where(disabled_reason: "revoked") }

  def pending?
    approved_at.nil? && disabled_at.nil?
  end

  def active?
    approved_at.present? && disabled_at.nil?
  end

  def denied?
    approved_at.nil? && disabled_at.present?
  end

  def revoked?
    disabled_reason == "revoked"
  end

  def approve!(approved_by:)
    raise ArgumentError, "only pending requests can be approved" unless pending?

    update!(approved_at: Time.current, approved_by: approved_by, token: self.class.generate_token)
  end

  def deny!(by:)
    raise ArgumentError, "only pending requests can be denied" unless pending?

    update!(disabled_at: Time.current, disabled_reason: "denied", disabled_by: by)
  end

  def revoke!(by:)
    raise ArgumentError, "only active tokens can be revoked" unless active?

    update!(disabled_at: Time.current, disabled_reason: "revoked", disabled_by: by)
  end

  def regenerate!(by:)
    raise ArgumentError, "only active tokens can be regenerated" unless active?

    transaction do
      update!(disabled_at: Time.current, disabled_reason: "regenerated", disabled_by: by)
      self.class.create!(user: user, requested_use: requested_use, approved_at: Time.current, approved_by: by, token: self.class.generate_token, exempt_from_rate_limit: exempt_from_rate_limit)
    end
  end

  def disable_for_account_deletion!
    return unless disabled_at.nil?

    update!(disabled_at: Time.current, disabled_reason: "account_deleted")
  end

  def self.generate_token
    loop do
      token = SecureRandom.base58(24)
      break token unless exists?(token: token)
    end
  end

  def self.currently_revoked?(user)
    where(user_id: user.id).order(created_at: :desc).first&.revoked? || false
  end

  def status_label
    return "Pending" if pending?
    return "Active" if active?
    return "Revoked" if revoked?
    "Denied" if denied?
  end

  private

  def token_present_when_approved
    errors.add(:token, "must be present once approved") if approved_at.present? && token.blank?
  end
end
