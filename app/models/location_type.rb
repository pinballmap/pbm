class LocationType < ApplicationRecord
  has_paper_trail
  has_many :locations
  has_many :suggested_locations

  default_scope { order 'name' }
end
