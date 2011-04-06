class MachineScoreXref < ActiveRecord::Base
  belongs_to :location_machine_xref
  belongs_to :user
  has_one :location, :through => :location_machine_xref
  has_one :machine, :through => :location_machine_xref

  scope :region, lambda {|name| 
    r = Region.find_by_name(name)
    joins(:location_machine_xref).joins(:location).where('location_machine_xref.id = machine_score_xrefs.location_machine_xref_id and location.id = location_machine_xref.location_id')
  }

  ENGLISH_SCORES = {
    1 => 'GC',
    2 => '1st',
    3 => '2nd',
    4 => '3rd',
    5 => '4th'
  }

  def sanitize_scores
    self.location_machine_xref.machine_score_xrefs.each do |msx|
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank < ? and score < ?', self.location_machine_xref_id, self.rank, self.score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank > ? and score > ?', self.location_machine_xref_id, self.rank, self.score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank = ? and id != ?', self.location_machine_xref_id, self.rank, self.id])
    end
  end
end
