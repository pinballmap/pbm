class Machine < ActiveRecord::Base
  belongs_to :location_machine_xref
  scope :by_name, proc { |name| where(:name.matches => "%#{name}%") }

  validates_presence_of :name
end
