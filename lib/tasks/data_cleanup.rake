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

  def user_submission_location_name
    UserSubmission.where.not(location_id: nil).where.not(location_name: nil).where(submission_type: %w[new_lmx new_condition remove_machine new_msx confirm_location ic_toggle new_picture]).each do |us|
      matched_location = Location.where("id = ?", us.location_id).first

      next if matched_location.nil? or (us.location_name == matched_location.name)

      if (us.submission_type = "new_lmx")
        us.location_name = matched_location.name
        us.submission = "#{us.machine_name} was added to #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
      elsif (us.submission_type = "new_condition")
        us.location_name = matched_location.name
        us.submission = "#{us.user_name} commented on #{us.machine_name} at #{us.location_name} in #{us.city_name}. They said: #{us.comment}" if field_presence? && us.machine_name.present? && us.comment.present?
      elsif (us.submission_type = "remove_machine")
        us.location_name = matched_location.name
        us.submission = "#{us.machine_name} was removed from #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
      elsif (us.submission_type = "new_msx")
        us.location_name = matched_location.name
        us.submission = "#{us.user_name} added a high score of #{number_with_precision(us.high_score, precision: 0, delimiter: ',')} on #{us.machine_name} at #{us.location_name} in #{us.city_name}." if field_presence?(us) && us.machine_name.present? && us.high_score.present?
      elsif (us.submission_type = "confirm_location")
        us.location_name = matched_location.name
        us.submission = "#{us.user_name} confirmed the lineup at #{us.location_name} in #{us.city_name}" if field_presence?(us)
      elsif (us.submission_type = "ic_toggle")
        us.location_name = matched_location.name
        us.submission = "Insider Connected toggled on #{us.machine_name} at #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
      elsif (us.submission_type = "new_picture")
        us.location_name = matched_location.name
        us.submission = "#{us.user_name} added a picture of #{us.location_name} in #{us.city_name}" if field_presence?(us)
      end
      us.save
    end
  end

  def field_presence?(us)
    us.user_name.present? && us.location_name.present? && us.city_name.present?
  end

  def delete_stale_locations
    Location.where(date_last_updated: (..7.years.ago)).each do |l|
      l.destroy
    end
  end

  apostrophe_fix
  us_phone
  user_submission_location_name
  delete_stale_locations
rescue StandardError => e
  error_subject = "Data cleanup rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
