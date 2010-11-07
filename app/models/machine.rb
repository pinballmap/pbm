class Machine < ActiveRecord::Base
  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }

  validates_presence_of :name
end
