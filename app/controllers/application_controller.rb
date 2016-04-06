class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def ensure_registration_complete
    unless current_user.locations.present?
      flash[:notice] = "Just one more thing..."
      redirect_to new_location_path
    end
  end

  def authenticate_user!
    if user_signed_in?
      super
    else
      redirect_to welcome_path
    end
  end

end
