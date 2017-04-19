class SuggestedLocation < ActiveRecord::Base
  belongs_to :region
  belongs_to :operator
  belongs_to :location_type

  attr_accessible :name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :region_id, :location_type_id, :comments, :operator_id, :machines, :operator, :location_type, :user_inputted_address
end
