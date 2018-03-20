class AddUserIdToMachineScoreXref < ActiveRecord::Migration[4.2]
  def self.up
    add_column :machine_score_xrefs, :user_id, :integer
  end

  def self.down
    remove_column :machine_score_xrefs, :user_id
  end
end
