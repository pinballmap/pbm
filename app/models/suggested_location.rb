class SuggestedLocation < ActiveRecord::Base
  belongs_to :region
  belongs_to :operator
  belongs_to :location_type

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: ENV['SKIP_GEOCODE']

  attr_accessible :name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :region_id, :location_type_id, :comments, :operator_id, :machines, :operator, :location_type, :user_inputted_address

  def full_street_address
    [street, city, state, zip].join(', ')
  end
end
