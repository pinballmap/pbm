class SuggestedLocation < ActiveRecord::Base
  validates_presence_of :name, :street, :city, :state, :zip
  validates :phone, format: { with: /\A(\(\d{3}\) |\d{3}-)\d{3}-\d{4}\z/, message: 'format invalid, please use ###-###-#### or (###) ###-####' }, if: :phone?
  validates :website, format: { with: %r{^http[s]?:\/\/}, message: 'must begin with http:// or https://', multiline: true }, if: :website?
  validates :name, :street, :city, :state, format: { with: /^\S.*/, message: "Can't start with a blank", multiline: true }
  validates :lat, :lon, presence: { message: 'Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon' }

  belongs_to :region
  belongs_to :operator
  belongs_to :location_type

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: ENV['SKIP_GEOCODE']

  attr_accessible :name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :region_id, :location_type_id, :comments, :operator_id, :machines, :region, :operator, :location_type, :user_inputted_address

  def full_street_address
    [street, city, state, zip].join(', ')
  end
end
