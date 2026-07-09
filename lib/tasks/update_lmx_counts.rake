desc "Updates machines.lmx_count with the current count of location_machine_xrefs per machine"
task update_lmx_counts: :environment do
  ActiveRecord::Base.connection.execute(<<~SQL)
    UPDATE machines
    SET lmx_count = counts.cnt
    FROM (
      SELECT m.id AS machine_id, COUNT(lmx.id) AS cnt
      FROM machines m
      LEFT JOIN location_machine_xrefs lmx
        ON lmx.machine_id = m.id AND lmx.deleted_at IS NULL
      GROUP BY m.id
    ) counts
    WHERE machines.id = counts.machine_id
  SQL

  Rails.cache.delete(Machine::MOBILE_CACHE_KEY_WITH_LMX_COUNT)
  Status.where(status_type: "machines").update(updated_at: Time.current)
rescue StandardError => e
  error_subject = "Update lmx counts rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
