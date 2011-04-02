class AddInitialsToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :initials, :string
  end

  def self.down
    remove_column :users, :initials
  end
end
