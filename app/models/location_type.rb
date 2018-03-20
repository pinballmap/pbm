class LocationType < ApplicationRecord
  has_many :locations
  has_many :suggested_locations

  default_scope { order 'name' }
end
