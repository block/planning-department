module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!

      private

      def authenticate_api_token!
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        @api_token = ApiToken.authenticate(token)

        unless @api_token
          render json: { error: "Invalid or expired API token" }, status: :unauthorized
        end
      end

      def current_user
        @api_token&.user
      end

      def current_organization
        @api_token&.organization
      end

      def set_plan
        @plan = current_organization.plans.find_by(id: params[:plan_id] || params[:id])
        unless @plan
          render json: { error: "Plan not found" }, status: :not_found
        end
      end

      def authorize_plan_access!
        return unless @plan
        policy = PlanPolicy.new(current_user, @plan)
        unless policy.show?
          render json: { error: "Plan not found" }, status: :not_found
        end
      end
    end
  end
end
