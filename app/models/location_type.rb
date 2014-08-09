class LocationType < ActiveRecord::Base
  has_many :locations

  default_scope order 'name'
end
