class CreateTableUserFaveLocation < ActiveRecord::Migration[5.2]
  def change
    create_table :user_fave_locations do |t|
      t.integer :user_id
      t.integer :location_id

      t.timestamps
    end
  end
end
