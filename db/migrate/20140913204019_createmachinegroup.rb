class Createmachinegroup < ActiveRecord::Migration[4.2]
  def up
    create_table :machine_groups do |t|
      t.string :name, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :machine_groups
  end
end
