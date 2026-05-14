class CreateUserMachineXrefs < ActiveRecord::Migration[7.2]
  def up
    create_table :user_machine_xrefs do |t|
      t.integer :user_id, null: false
      t.integer :machine_id, null: false
      t.timestamps
    end

    add_index :user_machine_xrefs, [ :user_id, :machine_id ], unique: true
    add_index :user_machine_xrefs, :machine_id
  end

  def down
    drop_table :user_machine_xrefs
  end
end
