class Operator < ActiveRecord::Base
  belongs_to :region
  has_many :location_machine_xrefs
end
