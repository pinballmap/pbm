class Operator < ActiveRecord::Base
  belongs_to :region
  has_many :locations

  attr_accessible :name, :region_id, :email, :website, :phone
end
