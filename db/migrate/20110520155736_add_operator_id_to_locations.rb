class AddOperatorIdToLocations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :locations, :operator_id, :integer
  end

  def self.down
    remove_column :locations, :operator_id
  end
end
