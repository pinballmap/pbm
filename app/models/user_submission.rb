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
  ACTIVITY_SUBMISSION_TYPES = %w[new_lmx remove_machine new_condition confirm_location].freeze
  ACTIVITY_START_DATE = "2019-05-03T07:00:00.00-07:00".freeze

  scope :activity_feed, lambda {
    where(
      submission_type: ACTIVITY_SUBMISSION_TYPES,
      created_at: ACTIVITY_START_DATE..Date.today.end_of_day,
      deleted_at: nil
    ).order("created_at DESC")
  }

  scope :at_location, ->(location) { where(location_id: location) }
  scope :with_coordinates, -> { where.not(lat: nil) }

  NEW_LMX_TYPE = "new_lmx".freeze
  CONTACT_US_TYPE = "contact_us".freeze
  NEW_CONDITION_TYPE = "new_condition".freeze
  REMOVE_MACHINE_TYPE = "remove_machine".freeze
  SUGGEST_LOCATION_TYPE = "suggest_location".freeze
  LOCATION_METADATA_TYPE = "location_metadata".freeze
  NEW_SCORE_TYPE = "new_msx".freeze
  CONFIRM_LOCATION_TYPE = "confirm_location".freeze
  DELETE_LOCATION_TYPE = "delete_location".freeze
  IC_TOGGLE_TYPE = "ic_toggle".freeze
  NEW_PICTURE_TYPE = "new_picture".freeze

  def user_email
    user ? user.email : ""
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
