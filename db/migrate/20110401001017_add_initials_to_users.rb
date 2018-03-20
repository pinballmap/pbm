class AddInitialsToUsers < ActiveRecord::Migration[4.2]
  def self.up
     add_column :users, :initials, :string
  end

  def self.down
    remove_column :users, :initials
  end
end
