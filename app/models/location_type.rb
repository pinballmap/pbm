class LocationType < ApplicationRecord
  has_many :locations

  default_scope { order 'name' }
end
