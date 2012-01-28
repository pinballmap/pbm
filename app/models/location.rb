class Location < ActiveRecord::Base
  validates_presence_of :name, :street, :city, :state, :zip
  belongs_to :location_type
  belongs_to :zone
  belongs_to :region
  belongs_to :operator
  has_many :events
  has_many :machines, :through => :location_machine_xrefs
  has_many :location_machine_xrefs
  has_many :location_picture_xrefs

  geocoded_by :full_street_address, :latitude  => :lat, :longitude => :lon
  after_validation :geocode, :unless => ENV['SKIP_GEOCODE']

  scope :region, lambda {|name| 
    r = Region.find_by_name(name)
    where(:region_id => r.id)
  }
  scope :by_type_id, lambda {|id| where(:location_type_id => id)}
  scope :by_operator_id, lambda {|id| where(:operator_id => id)}
  scope :by_location_id, lambda {|id| where(:id => id)}
  scope :by_zone_id, lambda {|id| where(:zone_id => id)}
  scope :by_city_id, lambda {|city| where(:city => city)}
  scope :by_location_name, lambda {|name| where(:name => name)}
  scope :by_machine_id, lambda {|id|
    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', id)
  }
  scope :by_machine_name, lambda {|name|
    machine = Machine.find_by_name(name)

    return nil if machine.nil?

    joins(:location_machine_xrefs).where('locations.id = location_machine_xrefs.location_id and location_machine_xrefs.machine_id = ?', machine.id)
  }

  before_destroy do |record| 
    Event.destroy_all "location_id = #{record.id}"
    LocationPictureXref.destroy_all "location_id = #{record.id}"
    MachineScoreXref.destroy_all "location_machine_xref_id in (select id from location_machine_xrefs where location_id = #{record.id})"
    LocationMachineXref.destroy_all "location_id = #{record.id}"
  end

  def machine_names
    self.machines.collect { |m| m.name }.sort
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\">"
    content += [self.name.gsub("'", "\\\\'"), self.street, [self.city, self.state, self.zip].join(', '), self.phone].join('<br />')
    content += '<br /><hr /><br />'

    machines = self.machines.sort_by { |m| m.name }.map {|m| m.name.gsub("'", "\\\\'") + '<br />'}

    content += machines.join
    content += "</div>'"

    content.html_safe
  end

  def full_street_address
    [self.street, self.city, self.state, self.zip].join(', ')
  end
end
