class RegionLinkXref < ActiveRecord::Base
  belongs_to :region

  scope :region, lambda {|name| where(:region_id => Region.find_by_name(name.downcase).id) }
end
