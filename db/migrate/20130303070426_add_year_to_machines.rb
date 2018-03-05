class AddYearToMachines < ActiveRecord::Migration[4.2]
  def up
    add_column :machines, :year, :integer
  end

  def down
    remove_column :machines, :year
  end
end
