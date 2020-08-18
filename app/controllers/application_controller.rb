class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  helper_method :current_user, :logged_in?
  private

  def current_user
    return nil unless session[:session_token]
    @current_user ||= User.find_by(session_token: session[:session_token])
  end

  def login!(user)
    session[:session_token] = user.reset_session_token!
    @current_user = user
  end

  def logout!
    @current_user.reset_session_token!
    @current_user = nil
    session[:session_token] = nil
  end

  def logged_in?
    !!current_user
  end

  def require_logged_in
    unless current_user
      render json: { base: ['invalid credentials'] }, status: 401
    end
  end

  def require_logged_out
    # redirect_to users_url if logged_in?
  end
end