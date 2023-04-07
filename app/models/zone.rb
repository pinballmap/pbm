class Zone < ApplicationRecord
  has_paper_trail
  validates_presence_of :name
  belongs_to :region, optional: true
  has_many :locations
  has_many :suggested_locations

  default_scope { order 'name' }

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id) })
end
