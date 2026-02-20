class ApiTokensController < ApplicationController
  before_action :scope_to_organization

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
  end

  def create
    raw_token = ApiToken.generate_token
    @api_token = current_user.api_tokens.create!(
      organization: @organization,
      name: params[:api_token][:name],
      token_digest: Digest::SHA256.hexdigest(raw_token)
    )
    @raw_token = raw_token
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
    flash.now[:notice] = "Token created. Copy it now — it won't be shown again."
    render :index
  rescue ActiveRecord::RecordInvalid => e
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
    flash.now[:alert] = e.message
    render :index, status: :unprocessable_entity
  end

  def revoke
    token = current_user.api_tokens.find(params[:id])
    token.revoke!
    redirect_to api_tokens_path, notice: "Token revoked."
  end
end
