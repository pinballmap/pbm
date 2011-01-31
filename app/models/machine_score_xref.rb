class MachineScoreXref < ActiveRecord::Base
  belongs_to :location_machine_xref
  has_one :location, :through => :location_machine_xref
  has_one :machine, :through => :location_machine_xref

  def sanitize_scores
    self.location_machine_xref.machine_score_xrefs.each do |msx|
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank < ? and score < ?', self.location_machine_xref_id, self.rank, self.score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank > ? and score > ?', self.location_machine_xref_id, self.rank, self.score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank = ? and id != ?', self.location_machine_xref_id, self.rank, self.id])
    end
  end
end
