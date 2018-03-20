class ChangeScoreFromIntToBigint < ActiveRecord::Migration[4.2]
  def self.up
    change_column :machine_score_xrefs, :score, :bigint
  end

  def self.down
    change_column :machine_score_xrefs, :score, :int
  end
end
