class RemoveInitialsFromUsers < ActiveRecord::Migration[8.0]
  def self.up
    remove_column :users, :initials
  end

  def self.down
    add_column :users, :initials, :string
  end
end
