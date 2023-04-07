class RegionLinkXref < ApplicationRecord
  has_paper_trail
  belongs_to :region, optional: true

  scope :region, (->(name) { where(region_id: Region.find_by_name(name.downcase).id) })
end
