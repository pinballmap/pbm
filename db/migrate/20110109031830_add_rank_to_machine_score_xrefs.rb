class AddRankToMachineScoreXrefs < ActiveRecord::Migration
  def self.up
    add_column :machine_score_xrefs, :rank, :string
  end

  def self.down
    remove_column :machine_score_xrefs, :rank
  end
end
