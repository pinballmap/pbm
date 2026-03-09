class AddMachineIdToMachineScoreXrefs < ActiveRecord::Migration[8.1]
  def self.up
    add_column :machine_score_xrefs, :machine_id, :integer
  end

  def self.down
    remove_column :machine_score_xrefs, :machine_id
  end
end
