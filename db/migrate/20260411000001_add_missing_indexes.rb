class AddMissingIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # location_machine_xrefs — default_scope filters deleted_at: nil on every LMX query
    add_index :location_machine_xrefs, :deleted_at, algorithm: :concurrently

    # user_fave_locations — no indexes at all; queried by user_id, location_id, and both together
    add_index :user_fave_locations, [:user_id, :location_id], algorithm: :concurrently
    add_index :user_fave_locations, :location_id, algorithm: :concurrently

    # locations — filter scopes exposed via the API
    add_index :locations, :state, algorithm: :concurrently
    add_index :locations, :country, algorithm: :concurrently
    add_index :locations, :ic_active, algorithm: :concurrently
    add_index :locations, :machine_count, algorithm: :concurrently
    add_index :locations, :place_id, algorithm: :concurrently

    # machines — filter scopes exposed via the API; opdb_id used heavily during sync jobs
    add_index :machines, :opdb_id, algorithm: :concurrently
    add_index :machines, :year, algorithm: :concurrently
    add_index :machines, :manufacturer, algorithm: :concurrently
    add_index :machines, :machine_type, algorithm: :concurrently
    add_index :machines, :machine_display, algorithm: :concurrently

    # machine_score_xrefs — queried by both user_id and machine_id together
    add_index :machine_score_xrefs, [:user_id, :machine_id], algorithm: :concurrently

    # suggested_locations — queried by region_id; no indexes on this table
    add_index :suggested_locations, :region_id, algorithm: :concurrently
  end

  def down
    remove_index :suggested_locations, :region_id
    remove_index :machine_score_xrefs, [:user_id, :machine_id]
    remove_index :machines, :machine_display
    remove_index :machines, :machine_type
    remove_index :machines, :manufacturer
    remove_index :machines, :year
    remove_index :machines, :opdb_id
    remove_index :locations, :place_id
    remove_index :locations, :machine_count
    remove_index :locations, :ic_active
    remove_index :locations, :country
    remove_index :locations, :state
    remove_index :user_fave_locations, :location_id
    remove_index :user_fave_locations, [:user_id, :location_id]
    remove_index :location_machine_xrefs, :deleted_at
  end
end
