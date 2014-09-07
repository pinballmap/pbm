class RegionLinkXref < ActiveRecord::Base
  belongs_to :region

  scope :region, ->(name) { where(region_id: Region.find_by_name(name.downcase).id) }

  attr_accessible :name, :url, :description, :category, :region_id, :sort_order
end
