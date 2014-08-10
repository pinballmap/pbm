class Event < ActiveRecord::Base
  belongs_to :region
  belongs_to :location

  scope :region, lambda {|name| where(:region_id => Region.find_by_name(name.downcase).id).to_a }

  attr_accessible :name, :long_desc, :start_date, :end_date
end
