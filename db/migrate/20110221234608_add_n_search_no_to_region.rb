class AddNSearchNoToRegion < ActiveRecord::Migration[4.2]
  def self.up
    add_column :regions, :n_search_no, :int
  end

  def self.down
    remove_column :regions, :n_search_no
  end
end
