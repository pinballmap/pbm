class ChangeMachineScoreXrefRankToInteger < ActiveRecord::Migration
  def self.up
    change_column :machine_score_xrefs, :rank, :integer
  end

  def self.down
    change_column :machine_score_xrefs, :rank, :string
  end
end
