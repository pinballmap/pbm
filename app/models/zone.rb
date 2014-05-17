class Zone < ActiveRecord::Base
  validates_presence_of :name
  belongs_to :region
  has_many :locations

  scope :region, lambda {|name| where(:region_id => Region.find_by_name(name.downcase).id) }
end
