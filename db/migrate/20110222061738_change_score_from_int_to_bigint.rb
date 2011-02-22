class ChangeScoreFromIntToBigint < ActiveRecord::Migration
  def self.up
    change_column :machine_score_xrefs, :score, :bigint
  end

  def self.down
    change_column :machine_score_xrefs, :score, :int
  end
end
