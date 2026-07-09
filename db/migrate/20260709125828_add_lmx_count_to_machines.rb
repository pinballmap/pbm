class AddLmxCountToMachines < ActiveRecord::Migration[8.1]
  def change
    add_column :machines, :lmx_count, :integer, default: 0, null: false
  end
end
