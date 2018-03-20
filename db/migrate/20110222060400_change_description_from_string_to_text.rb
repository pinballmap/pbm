class ChangeDescriptionFromStringToText < ActiveRecord::Migration[4.2]
  def self.up
    change_column :location_machine_xrefs, :condition, :text
  end

  def self.down
    change_column :location_machine_xrefs, :condition, :string
  end
end
