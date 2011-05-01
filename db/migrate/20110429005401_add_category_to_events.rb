class AddCategoryToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :category, :string
  end

  def self.down
    remove_column :events, :category
  end
end
