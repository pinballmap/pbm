class ChangeMachineScoreXrefRankToInteger < ActiveRecord::Migration
  def self.up
    remove_column :machine_score_xrefs, :rank
    add_column :machine_score_xrefs, :rank, :integer
  end

  def self.down
    remove_column :machine_score_xrefs, :rank
    add_column :machine_score_xrefs, :rank, :string
  end
end
