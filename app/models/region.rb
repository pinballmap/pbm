class Region < ActiveRecord::Base
  has_many :locations
  has_many :zones
  has_many :users
  has_many :events
  has_many :operators
  has_many :location_machine_xrefs, :through => :locations

  def n_recent_scores(n)
    MachineScoreXref.find_by_sql(<<HERE)
select location_machine_xref_id, rank, score, initials, machine_score_xrefs.created_at
from machine_score_xrefs, location_machine_xrefs
where machine_score_xrefs.location_machine_xref_id in (select id from location_machine_xrefs where location_id in (select id from locations where region_id = #{self.id}))
order by machine_score_xrefs.created_at desc
limit #{n}
HERE
  end
end
