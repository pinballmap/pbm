class ChangeLocationDescriptionFromStringToText < ActiveRecord::Migration[5.2]
  def self.up
    change_column :locations, :description, :text
  end

  def self.down
    change_column :locations, :description, :string
  end
end
