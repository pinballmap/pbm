class OperatorMailer < ApplicationMailer
  def send_recent_comments
    # @comment = params[:comment]
    # @location_name = params[:location_name]
    # @location_address = params[:location_address]
    # @machine = params[:machine]
    # @date = params[:date]
    @body = params[:body]

    mail(to: params[:email], subject: "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}")
  end
end
