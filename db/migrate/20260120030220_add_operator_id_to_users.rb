class AddOperatorIdToUsers < ActiveRecord::Migration[8.1]
  def self.up
    add_column :users, :operator_id, :integer
  end

  def self.down
    remove_column :users, :operator_id
  end
end
