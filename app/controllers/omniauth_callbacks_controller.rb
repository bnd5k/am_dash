class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    auth_data = request.env['omniauth.auth']
    @user = AMDash.find_or_create_from_google(auth_data)
    if @user
      redirect_to home_path
       sign_in_and_redirect @user
    else
      flash[:error] = "Something went wrong. Please try again."
      redirect_to new_user_session
    end
  end

end
