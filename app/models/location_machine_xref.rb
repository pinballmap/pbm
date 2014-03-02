class LocationMachineXref < ActiveRecord::Base
  belongs_to :location
  belongs_to :machine
  belongs_to :user
  has_many :machine_score_xrefs

  scope :region, lambda {|name|
    r = Region.find_by_name(name.downcase)
    joins(:location).where('locations.region_id = ?', r.id)
  }

  def haml_object_ref
    'lmx'
  end

  def update_condition(condition, options = {})
    self.condition = condition
    self.condition_date = Time.now
    self.save

    Pony.mail(
      :to => self.location.region.users.collect {|u| u.email},
      :from => 'admin@pinballmap.com',
      :subject => "PBM - Someone entered a machine condition",
      :body => [self.condition, self.machine.name, self.location.name, self.location.region.name, "(entered from #{options[:remote_ip]})"].join("\n")
    )
  end

  def destroy(options = {})
    if (self.location.region.should_email_machine_removal)
      Pony.mail(
          :to => self.location.region.users.collect {|u| u.email},
          :from => 'admin@pinballmap.com',
          :subject => "PBM - Someone removed a machine from a location",
          :body => [self.location.name, self.machine.name, self.location.region.name, "(entered from #{options[:remote_ip]})"].join("\n")
      )
    end

    super()
  end
end
