desc "Various regular data cleanup methods"
task data_cleanup: :environment do
  def apostrophe_fix
    Location.where("name ILIKE ?", "%’%").each do |l|
      l.name = l.name.gsub("’", "'")
      l.save
    end
  end

  def us_phone
    Location.where("LENGTH(phone) = ?", 10).where("phone !~ ?", "[^0-9]+").where(country: "US").each do |l|
      l.phone = l.phone.to_i.to_formatted_s(:phone)
      l.save
    end
  end

  apostrophe_fix
  us_phone
rescue StandardError => e
  error_subject = "Data cleanup rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
