class AddNSearchNoToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :n_search_no, :int
  end

  def self.down
    remove_column :regions, :n_search_no
  end
end
