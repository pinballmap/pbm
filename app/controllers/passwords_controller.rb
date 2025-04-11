class PasswordsController < Devise::PasswordsController
  respond_to :json
  rate_limit to: 5, within: 20.minutes, only: :create

  def create
    if params[:security_question] =~ /pinball/i && !is_bot?
      super
    else
      self.resource = resource_class.new
      flash.now[:alert] = "You failed the security test. Please go back and try again."
      respond_with_navigational(resource) { render :new }
    end
  end
end
