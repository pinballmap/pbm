class UserSubmission < ApplicationRecord
  has_paper_trail

  belongs_to :region, optional: true
  belongs_to :user, optional: true, counter_cache: true
  belongs_to :location, optional: true, counter_cache: :user_submissions_count
  belongs_to :machine, optional: true

  after_create :update_contributor_rank

  geocoded_by :lat_and_lon, latitude: :lat, longitude: :lon

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  # Activity feed scopes
  ACTIVITY_SUBMISSION_TYPES = %w[add_location new_lmx remove_machine new_condition confirm_location].freeze

  scope :activity_feed, ->(user) {
    where(
      submission_type: ACTIVITY_SUBMISSION_TYPES,
      deleted_at: nil
    ).or(where(submission_type: "new_msx", user_id: user&.id)).where.not(submission: nil).order("created_at DESC")
  }

  # Builds the activity filter scope. "new_msx" means the current user's scores
  # (ignored when logged out); "all_msx" means every user's scores.
  def self.activity_scope(requested_types, user)
    all_scores = requested_types.include?("all_msx")
    own_scores = requested_types.include?("new_msx") && user.present?
    general_types = requested_types.excluding("new_msx", "all_msx")

    scopes = []
    scopes << where(submission_type: general_types) if general_types.any?
    if all_scores
      scopes << where(submission_type: "new_msx")
    elsif own_scores
      scopes << where(submission_type: "new_msx", user: user)
    end
    return none if scopes.empty?

    scopes.reduce(:or).where(deleted_at: nil)
  end

  scope :at_location, ->(location) { where(location_id: location) }
  scope :with_coordinates, -> { where.not(lat: nil) }

  NEW_LMX_TYPE = "new_lmx".freeze
  CONTACT_US_TYPE = "contact_us".freeze
  NEW_CONDITION_TYPE = "new_condition".freeze
  REMOVE_MACHINE_TYPE = "remove_machine".freeze
  SUGGEST_LOCATION_TYPE = "suggest_location".freeze
  ADD_LOCATION_TYPE = "add_location".freeze
  LOCATION_METADATA_TYPE = "location_metadata".freeze
  NEW_SCORE_TYPE = "new_msx".freeze
  CONFIRM_LOCATION_TYPE = "confirm_location".freeze
  DELETE_LOCATION_TYPE = "delete_location".freeze
  IC_TOGGLE_TYPE = "ic_toggle".freeze
  NEW_PICTURE_TYPE = "new_picture".freeze
  REMOVE_PICTURE_TYPE = "remove_picture".freeze

  def user_email
    user&.email
  end

  def user_operator_id
    user&.operator_id
  end

  def admin_title
    user&.admin_title
  end

  def contributor_rank
    user&.contributor_rank
  end

  def flag
    user&.flag
  end

  def user_deleted
    user_id.present? && user.blank?
  end

  def location_operator_id
    location&.operator_id
  end

  def lat_and_lon
    [ lat, lon ].join(", ")
  end

  def update_contributor_rank
    if user
      case user.user_submissions_count
      when 51...250
        user.contributor_rank = "Super Mapper"
      when 251...500
        user.contributor_rank = "Legendary Mapper"
      when 501...Float::INFINITY
        user.contributor_rank = "Grand Champ Mapper"
      end
      user.save
    end
  end
end
