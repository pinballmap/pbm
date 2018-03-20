class AddTableSuggestedLocation < ActiveRecord::Migration[4.2]
  def change
    create_table :suggested_locations do |t|
	t.text :name
	t.text :street
	t.text :city
	t.text :state
	t.text :zip
	t.text :phone
	t.text :website
	t.integer :location_type_id
	t.integer :operator_id
	t.integer :region_id
	t.text :comments
	t.text :machines
	t.text :user_inputted_address
        t.decimal :lat, :scale => 12, :precision => 18
        t.decimal :lon, :scale => 12, :precision => 18
    end
  end
end
