class Region < ActiveRecord::Base
  has_many :locations
  has_many :zones
  has_many :users
  has_many :events
  has_many :operators
  has_many :region_link_xrefs
  has_many :location_machine_xrefs, :through => :locations

  def machines
    machines = Array.new
    self.location_machine_xrefs.includes(:machine).sort{|a,b| a.machine.name <=> b.machine.name}.each do |lmx|
      machines << lmx.machine
    end

    machines.uniq
  end

  def machine_score_xrefs
    machine_score_xrefs = Array.new

    self.location_machine_xrefs.includes(:machine_score_xrefs, :location, :machine).each do |lmx|
      machine_score_xrefs += lmx.machine_score_xrefs if lmx.machine_score_xrefs
    end

    machine_score_xrefs
  end

  def n_recent_scores(n)
    scores = self.machine_score_xrefs.sort {|a,b| b.id <=> a.id}
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

  def primary_email_contact
    self.users.empty? ? 'email_not_found@noemailfound.noemail' : self.users[0].email
  end
end
