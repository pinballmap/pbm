require "uri"

class SuggestedLocation < ApplicationRecord
  has_paper_trail
  validates_presence_of :name, :machines, on: :create
  validates_presence_of :street, :city, :zip, on: :update

  validates :website, format: { with: %r{\Ahttp(s?)://}, message: "must begin with http:// or https://" }, if: :website?, on: :update
  validates :name, :street, :city, format: { with: /\A\S.*/, message: "Can't start with a blank", multiline: true }, on: :update
  validates :lat, :lon, presence: { message: "Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon" }, on: :update

  belongs_to :region, optional: true
  belongs_to :operator, optional: true
  belongs_to :zone, optional: true
  belongs_to :location_type, optional: true

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: :skip_geocoding?
  strip_attributes

  after_create :massage_fields

  def massage_fields
    self.country = "US" if country.blank?
    self.website = "http://#{website}" if website && !website.blank? && website !~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/

    save
  end

  def skip_geocoding?
    address_incomplete? || ENV["SKIP_GEOCODE"] || (lat && lon)
  end

  def address_incomplete?
    street.nil? || city.nil?
  end

  def full_street_address
    [ street, city, state, zip ].compact.join(", ")
  end

  def convert_to_location(user_email)
    if country.blank? || country.nil?
      errors.add(:base, "Country is a required field for conversion.")

      return
    end

    if !phone.blank? && (Phonelib.invalid? phone)
      errors.add(:base, "Phone format not valid. Try adding the country code.")

      return
    end

    location = Location.create(name: name, street: street, city: city, state: state, zip: zip, country: country, phone: phone, lat: lat, lon: lon, website: website, description: comments, region_id: region_id, location_type_id: location_type_id, operator_id: operator_id, zone_id: zone_id, last_updated_by_user_id: user_id)

    if !location.valid?
      errors.add(:base, location.errors.first)
    else
      if !machines&.start_with?("[")
        machines.tr!("[", "(")
        machines.tr!("]", ")")
        machines.gsub!(/ - /, ", ")

        machines.split(/([^,]*,[^,]*,)/).each do |machine_info|
          next if machine_info.blank?

          machine_info.strip!

          matches = machine_info.match(/.*\((.*), (.*)\)/i)

          next if matches.nil?

          manufacturer, year = matches.captures

          machine_info.slice!(machine_info.rindex(manufacturer), manufacturer.size)
          machine_info.slice!(machine_info.rindex(year), year.size)
          machine_info.sub!(" (, ),", "")

          name = machine_info

          name.strip!
          manufacturer.strip!
          year.strip!

          machine = Machine.find_by(name: name, year: year, manufacturer: manufacturer)

          LocationMachineXref.create(location_id: location.id, machine_id: machine.id) unless machine.nil?
        end
      else
        machine_ids = machines.gsub(/[\[\]" ]/, "").split(",").map(&:to_i)
        machine_ids&.each do |machine_id|
          machine = Machine.find_by(id: machine_id)
          LocationMachineXref.create(location_id: location.id, machine_id: machine.id, user_id: user_id) unless machine.nil?
        end
      end

      delete

      sql = <<HERE
insert into versions values (
  nextval('versions_id_seq'),
  'Location',
  :location_id,
  'converted from suggested location',
  :user_email,
  NULL,
  now(),
  NULL,
  NULL
)
HERE
      sanitized_sql = ActiveRecord::Base.sanitize_sql_array([ sql, { location_id: location.id, user_email: user_email } ])
      ActiveRecord::Base.connection.execute(sanitized_sql)
    end
  end
end
