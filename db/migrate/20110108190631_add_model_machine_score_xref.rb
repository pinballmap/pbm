class AddModelMachineScoreXref < ActiveRecord::Migration
  def self.up
    create_table :machine_score_xrefs do |t|
      t.integer :location_machine_xref_id
      t.integer :score
      t.string :initials

      t.timestamps
    end
  end

  def self.down
    drop_table :machine_score_xrefs
  end
end
