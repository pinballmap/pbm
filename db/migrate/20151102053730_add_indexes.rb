class AddIndexes < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.index :region_id
      t.index :location_id
      t.index :ifpa_calendar_id
      t.index :ifpa_tournament_id
    end

    change_table :location_machine_xrefs do |t|
      t.index :user_id
    end

    change_table :location_picture_xrefs do |t|
      t.index :location_id
      t.index :user_id
    end

    change_table :locations do |t|
      t.index :zone_id
      t.index :region_id
      t.index :location_type_id
      t.index :operator_id
    end

    change_table :machine_score_xrefs do |t|
      t.index :user_id
    end

    change_table :machines do |t|
      t.index :machine_group_id
    end

    change_table :operators do |t|
      t.index :region_id
    end

    change_table :region_link_xrefs do |t|
      t.index :region_id
    end

    change_table :users do |t|
      t.index :region_id
    end

    change_table :zones do |t|
      t.index :region_id
    end
  end
end
