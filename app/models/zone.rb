class Zone < ActiveRecord::Base
  validates_presence_of :name
  belongs_to :region
  has_many :locations

  attr_accessible :name, :region_id, :short_name, :is_primary

  default_scope { order 'name' }

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }
end
