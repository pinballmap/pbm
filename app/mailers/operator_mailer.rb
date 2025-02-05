class OperatorMailer < ApplicationMailer
  def send_daily_digest_operator_email
    @machine_comments = params[:machine_comments]
    @machines_added = params[:machines_added]
    @machines_removed = params[:machines_removed]

    mail(to: params[:email_to], subject: "Pinball Map - Daily digest of edits to your locations - #{Date.today.strftime('%m/%d/%Y')}")
  end
end
