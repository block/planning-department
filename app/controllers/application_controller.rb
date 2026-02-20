class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_attributes

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless signed_in?
      redirect_to sign_in_path, alert: "Please sign in."
    end
  end

  def authorize!(record, action)
    policy_class = "#{record.class}Policy".constantize
    policy = policy_class.new(current_user, record)
    unless policy.public_send(action)
      raise NotAuthorizedError
    end
  end

  class NotAuthorizedError < StandardError; end

  rescue_from NotAuthorizedError do
    head :not_found
  end

  def scope_to_organization
    @organization = Current.organization
  end

  def authenticate_admin!
    authenticate_user!
    redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
  end

  def set_current_attributes
    Current.user = current_user
    Current.organization = current_user&.organization
  end
end
