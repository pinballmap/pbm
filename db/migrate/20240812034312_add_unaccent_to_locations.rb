class AddUnaccentToLocations < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE OR REPLACE FUNCTION clean_items(item text)
        RETURNS text AS $$
        BEGIN
          RETURN regexp_replace(unaccent(item), '[[:punct:]]', '', 'g');
        END;
        $$ LANGUAGE plpgsql immutable returns null on null input;
      CREATE INDEX ix_fast_search_name ON locations (clean_items(name));
      CREATE INDEX ix_fast_search_city ON locations (clean_items(city));
    SQL
  end
  def down
    execute <<-SQL
      DROP EXTENSION IF EXISTS unaccent;
      DROP FUNCTION clean_items(item text);
      DROP INDEX ix_fast_search_name;
      DROP INDEX ix_fast_search_city;
    SQL
  end
end
