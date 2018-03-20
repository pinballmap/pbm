class RegionLinkXref < ApplicationRecord
  belongs_to :region, optional: true

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id) })
end
