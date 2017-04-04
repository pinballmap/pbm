class LocationType < ActiveRecord::Base
  has_many :locations

  attr_accessible :name

  default_scope { order 'name' }
end
