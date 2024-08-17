class AddFastSearchIndexes < ActiveRecord::Migration[7.0]
  def up
    enable_extension :pg_trgm
    execute <<-SQL
      DROP INDEX if exists location_names_fast_search_idx;
      DROP INDEX if exists location_city_fast_search_idx;
      DROP INDEX if exists machine_names_fast_search_idx;
      CREATE INDEX location_names_fast_search_idx on locations USING gin( (clean_items(name)) gin_trgm_ops);
      CREATE INDEX location_city_fast_search_idx on locations USING gin( (clean_items(city)) gin_trgm_ops);
      CREATE INDEX machine_names_fast_search_idx on machines USING gin( (clean_items(name)) gin_trgm_ops);
    SQL
  end

  def down
    disable_extension :pg_trgm
    execute <<-SQL
      DROP INDEX if exists location_names_fast_search_idx;
      DROP INDEX if exists location_city_fast_search_idx;
      DROP INDEX if exists machine_names_fast_search_idx;
    SQL
  end
end
