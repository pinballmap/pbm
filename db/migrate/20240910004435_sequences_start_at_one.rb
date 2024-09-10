class SequencesStartAtOne < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER SEQUENCE public.location_types_id_seq START WITH 1;
      ALTER SEQUENCE public.operators_id_seq START WITH 1;
      ALTER SEQUENCE public.region_link_xrefs_id_seq START WITH 1;
      ALTER SEQUENCE public.regions_id_seq START WITH 1;
      ALTER SEQUENCE public.users_id_seq START WITH 1;
      ALTER SEQUENCE public.zones_id_seq START WITH 1;
    SQL
  end

  def down
    execute <<-SQL
      ALTER SEQUENCE public.location_types_id_seq START WITH 34;
      ALTER SEQUENCE public.operators_id_seq START WITH 34;
      ALTER SEQUENCE public.region_link_xrefs_id_seq START WITH 2;
      ALTER SEQUENCE public.regions_id_seq START WITH 24;
      ALTER SEQUENCE public.users_id_seq START WITH 31;
      ALTER SEQUENCE public.zones_id_seq START WITH 185;
    SQL
  end
end
