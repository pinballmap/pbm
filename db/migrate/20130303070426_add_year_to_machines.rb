class AddYearToMachines < ActiveRecord::Migration
  def up
    add_column :machines, :year, :integer
  end

  def down
    remove_column :machines, :year
  end
end
