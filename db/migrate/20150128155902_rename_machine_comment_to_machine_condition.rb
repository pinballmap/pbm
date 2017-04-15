class RenameMachineCommentToMachineCondition < ActiveRecord::Migration
   def self.up
      rename_table :machine_comments, :machine_conditions
   end

   def self.down
      rename_table :machine_comments, :machine_conditions
   end
end
