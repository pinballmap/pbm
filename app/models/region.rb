class Region < ActiveRecord::Base
  has_many :locations
  has_many :zones
  has_many :users
  has_many :events
  has_many :operators
  has_many :region_link_xrefs
  has_many :location_machine_xrefs, :through => :locations

  attr_accessible :name, :full_name, :motd, :lat, :lon, :n_search_no, :default_search_type, :should_email_machine_removal

  def machines
    machines = Hash.new
    self.location_machine_xrefs.includes(:machine).each do |lmx|
      machines[lmx.machine.id] = lmx.machine
    end

    machines.values.sort_by(&:name)
  end

  def machine_score_xrefs
    machine_score_xrefs = Array.new

    self.location_machine_xrefs.includes(:machine_score_xrefs, :location, :machine).each do |lmx|
      machine_score_xrefs += lmx.machine_score_xrefs if lmx.machine_score_xrefs
    end

    machine_score_xrefs
  end

  def n_recent_scores(n)
    scores = self.machine_score_xrefs.sort_by(&:id)
    scores[0, n]
  end

  def n_high_rollers(n)
    rollers = Hash.new
    @high_rollers = Hash.new

    self.machine_score_xrefs.each do |msx|
      (rollers[msx.initials] ||= []) << msx
    end

    rollers.sort{|a,b| b[1].size <=> a[1].size}.each do |roller|
      @high_rollers[roller[0]] = roller[1] unless @high_rollers.size == n
    end

    @high_rollers
  end

  def all_admin_email_addresses
    if (self.users.empty?)
      [ 'email_not_found@noemailfound.noemail' ]
    else
      self.users.collect {|u| u.email}
    end
  end

  def primary_email_contact
    if (self.users.empty?)
      'email_not_found@noemailfound.noemail'
    elsif (self.users.any? { |u| u.is_primary_email_contact } )
      primary_email_contact = self.users.detect { |u| u.is_primary_email_contact }
      primary_email_contact.email
    else
      self.users[0].email
    end
  end

  def machineless_locations
    machineless_locations = Array.new

    self.locations.each { |l| machineless_locations.push(l) unless l.machines.size > 0 }

    machineless_locations
  end

  def locations_count
    Location.count_by_sql "select count(*) from locations where region_id=#{self.id}"
  end

  def machines_count
    LocationMachineXref.count_by_sql "select count(*) from location_machine_xrefs lmx inner join locations l on (lmx.location_id = l.id) where l.region_id=#{self.id}"
  end

  def available_search_sections
    sections = [ 'city', 'location', 'machine', 'type' ]

    if (self.operators.size > 0)
      sections.push('operator')
    end

    if (self.zones.size > 0)
      sections.push('zone')
    end

    '[' + sections.collect {|s| "'" + s + "'"}.join(', ') + ']'
  end

  def content_for_infowindow
    content = "'<div class=\"infowindow\" id=\"infowindow_#{self.id}\">"
    content += "<div class=\"gm_region_name\"><a href=\"#{self.name}\">#{self.full_name.gsub("'", "\\\\'")}</a></div>"
    content += '<hr />'
    content += "<div class=\"gm_location_count\">#{self.locations.size} Locations</div>"
    content += "<div class=\"gm_machine_count\">#{self.location_machine_xrefs.size} Machines</div>"
    content += "</div>'"

    content.html_safe
  end
end
