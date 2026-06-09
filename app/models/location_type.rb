class LocationType < ApplicationRecord
  has_paper_trail
  has_many :locations
  has_many :suggested_locations

  default_scope { order "name" }

  MOBILE_CACHE_KEY = "api/v1/location_types/index"

  before_save do
    Status.where(status_type: "location_types").update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: "location_types").update({ updated_at: Time.current })
  end

  after_commit -> { Rails.cache.delete(MOBILE_CACHE_KEY) }
end
