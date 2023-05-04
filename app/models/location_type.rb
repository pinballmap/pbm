class LocationType < ApplicationRecord
  has_many :locations
  has_many :suggested_locations

  default_scope { order 'name' }

  before_save do
    Status.where(status_type: 'location_types').update({ updated_at: Time.current })
  end

  before_destroy do
    Status.where(status_type: 'location_types').update({ updated_at: Time.current })
  end
end
