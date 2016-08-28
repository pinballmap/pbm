class RemoveRankFromMachineScoreXrefs < ActiveRecord::Migration
  def change
    remove_column :machine_score_xrefs, :rank
  end
end
