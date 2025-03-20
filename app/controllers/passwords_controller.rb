class PasswordsController < Devise::PasswordsController
  respond_to :json

  def create
    if params[:security_question] =~ /pinball/i
      super
    else
      self.resource = resource_class.new
      flash.now[:alert] = "You failed the security test. Please go back and try again."
      respond_with_navigational(resource) { render :new }
    end
  end
end
