class Event < ActiveRecord::Base
  belongs_to :region
  belongs_to :location
end
