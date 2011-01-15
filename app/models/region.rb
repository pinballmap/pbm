class Region < ActiveRecord::Base
  has_many :locations
  has_many :zones
  has_many :users
end
