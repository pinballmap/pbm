class OperatorMailer < ApplicationMailer
  def send_recent_comments
    @comments = params[:comments]
    @heading = params[:heading]

    mail(to: params[:email], subject: "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}")
  end
end
