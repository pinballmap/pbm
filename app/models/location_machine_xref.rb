class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  belongs_to :user
  has_many :machine_score_xrefs

  attr_accessible :machine_id, :location_id, :condition, :condition_date, :ip, :user_id

  scope :region, lambda {|name|
    r = Region.find_by_name(name.downcase)
    joins(:location).where('locations.region_id = ?', r.id)
  }

  def haml_object_ref
    'lmx'
  end

  def update_condition(condition, options = {})
    self.condition = condition
    self.condition_date = Time.now.strftime('%Y-%m-%d')
    save

    return if condition.nil? || condition.blank?

    Pony.mail(
      to: location.region.users.map { |u| u.email },
      from: 'admin@pinballmap.com',
      subject: 'PBM - Someone entered a machine condition',
      body: [condition, machine.name, location.name, location.region.name, "(entered from #{options[:remote_ip]})"].join("\n")
    )
  end

  def destroy(options = {})
    if location.region.should_email_machine_removal
      Pony.mail(
          to: location.region.users.map { |u| u.email },
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone removed a machine from a location',
          body: [location.name, machine.name, location.region.name, "(entered from #{options[:remote_ip]})"].join("\n")
      )
    end

    super()
  end
end
