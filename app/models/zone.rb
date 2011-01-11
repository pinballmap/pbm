class Zone < ActiveRecord::Base
  validates_presence_of :name
  belongs_to :region
  has_many :locations
end
