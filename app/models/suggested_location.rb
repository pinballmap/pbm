class SuggestedLocation < ActiveRecord::Base
  validates_presence_of :name, :street, :city, :state, :zip, on: :update

  validates :phone, format: { with: /\A(\(\d{3}\) |\d{3}-)\d{3}-\d{4}\z/, message: 'format invalid, please use ###-###-#### or (###) ###-####' }, if: :phone?, on: :update
  validates :website, format: { with: %r{^http[s]?:\/\/}, message: 'must begin with http:// or https://', multiline: true }, if: :website?, on: :update
  validates :name, :street, :city, :state, format: { with: /^\S.*/, message: "Can't start with a blank", multiline: true }, on: :update
  validates :lat, :lon, presence: { message: 'Latitude/Longitude failed to generate. Please double check address and try again, or manually enter the lat/lon' }, on: :update

  belongs_to :region
  belongs_to :operator
  belongs_to :location_type

  geocoded_by :full_street_address, latitude: :lat, longitude: :lon
  before_validation :geocode, unless: ENV['SKIP_GEOCODE']

  attr_accessible :name, :street, :city, :state, :zip, :phone, :lat, :lon, :website, :region_id, :location_type_id, :comments, :operator_id, :machines, :region, :operator, :location_type, :user_inputted_address

  def full_street_address
    [street, city, state, zip].join(', ')
  end

  def convert_to_location(user_email)
    location = Location.create(name: name, street: street, city: city, state: state, zip: zip, phone: phone, lat: lat, lon: lon, website: website, region_id: region_id, location_type_id: location_type_id, operator_id: operator_id)

    if !location.valid?
      errors.add(:base, location.errors.first)
    else
      if machines
        machines.tr!('[', '(')
        machines.tr!(']', ')')
        machines.gsub!(/ - /, ', ')

        machines.split(/([^,]*,[^,]*,)/).each do |machine_info|
          next if machine_info.blank?
          machine_info.strip!

          matches = machine_info.match(/.*\((.*), (.*)\)/i)

          next if matches.nil?

          manufacturer, year = matches.captures

          machine_info.slice!(machine_info.rindex(manufacturer), manufacturer.size)
          machine_info.slice!(machine_info.rindex(year), year.size)
          machine_info.sub!(' (, ),', '')

          name = machine_info

          name.strip!
          manufacturer.strip!
          year.strip!

          machine = Machine.find_by(name: name, year: year, manufacturer: manufacturer)

          LocationMachineXref.create(location_id: location.id, machine_id: machine.id) unless machine.nil?
        end
      end

      delete

      ActiveRecord::Base.connection.execute(<<HERE)
insert into rails_admin_histories values (
  nextval('rails_admin_histories_id_seq'),
  'converted from suggested location',
  '#{user_email}',
  #{location.id},
  'Location',
  NULL,
  NULL,
  now(),
  now()
)
HERE
    end
  end
end
