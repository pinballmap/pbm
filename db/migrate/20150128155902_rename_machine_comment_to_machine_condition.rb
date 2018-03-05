class RenameMachineCommentToMachineCondition < ActiveRecord::Migration[4.2]
   def self.up
      rename_table :machine_comments, :machine_conditions
   end

   def self.down
      rename_table :machine_comments, :machine_conditions
   end
end
