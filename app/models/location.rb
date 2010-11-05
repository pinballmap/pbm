class Location < ActiveRecord::Base
  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }
end
