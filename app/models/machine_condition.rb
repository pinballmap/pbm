class MachineCondition < ActiveRecord::Base
   belongs_to :location_machine_xref

   attr_accessible :comment,:location_machine_xref

end
