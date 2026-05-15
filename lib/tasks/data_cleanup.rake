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
    UserSubmission
      .joins("INNER JOIN locations ON locations.id = user_submissions.location_id")
      .where(submission_type: %w[new_lmx new_condition remove_machine new_msx confirm_location ic_toggle new_picture remove_picture add_location])
      .where.not(location_name: nil)
      .where("user_submissions.location_name != locations.name OR user_submissions.city_name IS DISTINCT FROM locations.city")
      .select("user_submissions.*, locations.name AS matched_location_name, locations.city AS matched_city")
      .each do |us|
        us.location_name = us.matched_location_name
        us.city_name = us.matched_city

        case us.submission_type
        when "new_lmx"
          us.submission = "#{us.machine_name} was added to #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_condition"
          us.submission = "#{us.user_name} commented on #{us.machine_name} at #{us.location_name} in #{us.city_name}. They said: #{us.comment}" if field_presence?(us) && us.machine_name.present? && us.comment.present?
        when "remove_machine"
          us.submission = "#{us.machine_name} was removed from #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_msx"
          us.submission = "#{us.user_name} added a high score of #{ActiveSupport::NumberHelper.number_to_delimited(us.high_score.to_i)} on #{us.machine_name} at #{us.location_name} in #{us.city_name}." if field_presence?(us) && us.machine_name.present? && us.high_score.present?
        when "confirm_location"
          us.submission = "#{us.user_name} confirmed the lineup at #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "ic_toggle"
          us.submission = "Insider Connected toggled on #{us.machine_name} at #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_picture"
          us.submission = "#{us.user_name} added a picture of #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "remove_picture"
          us.submission = "#{us.user_name} removed a picture of #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "add_location"
          us.submission = "New location added: #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us)
        end

        us.save
      end
  end

  def user_submission_user_name
    UserSubmission
      .joins("INNER JOIN users ON users.id = user_submissions.user_id")
      .where(submission_type: %w[new_lmx new_condition remove_machine new_msx confirm_location ic_toggle new_picture remove_picture add_location])
      .where.not(user_name: nil)
      .where("user_submissions.user_name != users.username")
      .select("user_submissions.*, users.username AS current_username")
      .each do |us|
        us.user_name = us.current_username

        case us.submission_type
        when "new_lmx"
          us.submission = "#{us.machine_name} was added to #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_condition"
          us.submission = "#{us.user_name} commented on #{us.machine_name} at #{us.location_name} in #{us.city_name}. They said: #{us.comment}" if field_presence?(us) && us.machine_name.present? && us.comment.present?
        when "remove_machine"
          us.submission = "#{us.machine_name} was removed from #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_msx"
          us.submission = "#{us.user_name} added a high score of #{ActiveSupport::NumberHelper.number_to_delimited(us.high_score.to_i)} on #{us.machine_name} at #{us.location_name} in #{us.city_name}." if field_presence?(us) && us.machine_name.present? && us.high_score.present?
        when "confirm_location"
          us.submission = "#{us.user_name} confirmed the lineup at #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "ic_toggle"
          us.submission = "Insider Connected toggled on #{us.machine_name} at #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us) && us.machine_name.present?
        when "new_picture"
          us.submission = "#{us.user_name} added a picture of #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "remove_picture"
          us.submission = "#{us.user_name} removed a picture of #{us.location_name} in #{us.city_name}" if field_presence?(us)
        when "add_location"
          us.submission = "New location added: #{us.location_name} in #{us.city_name} by #{us.user_name}" if field_presence?(us)
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

  def delete_orphan_scores
    MachineScoreXref.where(user_id: nil).each do |msx|
      msx.destroy
    end
  end

  apostrophe_fix
  us_phone
  user_submission_location_name
  user_submission_user_name
  delete_stale_locations
  delete_orphan_scores
rescue StandardError => e
  error_subject = "Data cleanup rake task error"
  error = e.to_s
  ErrorMailer.with(error: error, error_subject: error_subject).rake_task_error.deliver_later
end
