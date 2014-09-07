class MachineScoreXref < ActiveRecord::Base
  belongs_to :user
  belongs_to :location_machine_xref, counter_cache: true
  has_one :location, through: :location_machine_xref
  has_one :machine, through: :location_machine_xref

  attr_accessible :initials, :rank, :score, :location_machine_xref_id

  scope :region, lambda {|name|
    r = Region.find_by_name(name)
    joins(:location_machine_xref).joins(:location).where("
      location_machine_xrefs.id = machine_score_xrefs.location_machine_xref_id
      and locations.id = location_machine_xrefs.location_id
      and locations.region_id = #{r.id}
    ")
  }

  ENGLISH_SCORES = {
    1 => 'GC',
    2 => '1st',
    3 => '2nd',
    4 => '3rd',
    5 => '4th'
  }

  def sanitize_scores
    location_machine_xref.machine_score_xrefs.each do
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank < ? and score < ?', location_machine_xref_id, rank, score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank > ? and score > ?', location_machine_xref_id, rank, score])
      MachineScoreXref.delete_all(['location_machine_xref_id = ? and rank = ? and id != ?', location_machine_xref_id, rank, id])
    end
  end
end
