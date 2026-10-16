desc "Syncs the next six months of IFPA tournaments into the pbm database"
task import_ifpa_tournaments: :environment do
  importer = IfpaTournamentImporter.run(logger: Logger.new($stdout))

  if importer.errors.any?
    ErrorMailer.with(error: importer.errors.join("\n"), error_subject: "Import IFPA rake task error").rake_task_error.deliver_later
  end
rescue StandardError => e
  ErrorMailer.with(error: e.to_s, error_subject: "Import IFPA rake task error").rake_task_error.deliver_later
end
