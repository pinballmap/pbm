desc 'Makes a database backup that is scrubbed'
task dump_scrubbed_db: :environment do
  puts 'Run the following commands:'
  puts ''
  puts '# Obtain a server backup via:'
  puts 'pg_dump [pbm db name/url] > pbm_dump.sql'
  puts
  puts '# Drop and create the scrubdb if it is there:'
  puts 'dropdb pbm_scrubbed'
  puts 'createdb pbm_scrubbed'
  puts 'psql -d pbm_scrubbed < pbm_dump.sql'
  puts 'psql -d pbm_scrubbed < ./lib/database/scrub_db.sql'
  puts 'pg_dump pbm_scrubbed > pbm_scrubbed.sql'
  puts 'rm pbm_dump.sql # if you want to delete the original backup'
end
