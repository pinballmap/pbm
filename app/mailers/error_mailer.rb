class ErrorMailer < ApplicationMailer
  def rake_task_error
    @error_subject = params[:error_subject]
    @error = params[:error]
    mail(to: "admin@pinballmap.com", subject: "Pinball Map - #{@error_subject} - #{Date.today.strftime('%m/%d/%Y')}")
  end
end
