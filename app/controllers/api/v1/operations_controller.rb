module Api
  module V1
    class OperationsController < BaseController
      before_action :set_plan
      before_action :authorize_plan_access!

      def create
        lease_token = params[:lease_token]
        base_revision = params[:base_revision]&.to_i
        operations = params[:operations]

        unless lease_token.present?
          render json: { error: "lease_token is required" }, status: :unprocessable_entity
          return
        end

        unless base_revision.present?
          render json: { error: "base_revision is required" }, status: :unprocessable_entity
          return
        end

        unless operations.is_a?(Array) && operations.any?
          render json: { error: "operations must be a non-empty array" }, status: :unprocessable_entity
          return
        end

        lease = @plan.edit_lease
        unless lease&.held_by?(lease_token: lease_token)
          render json: { error: "You do not hold a valid edit lease for this plan" }, status: :conflict
          return
        end

        if @plan.current_revision != base_revision
          render json: {
            error: "Stale revision. Expected #{@plan.current_revision}, got #{base_revision}",
            current_revision: @plan.current_revision
          }, status: :conflict
          return
        end

        current_content = @plan.current_content || ""
        result = Plans::ApplyOperations.call(content: current_content, operations: operations)

        previous_content = current_content
        new_revision = @plan.current_revision + 1

        diff = Diffy::Diff.new(previous_content, result[:content]).to_s

        version = PlanVersion.create!(
          plan: @plan,
          organization: current_organization,
          revision: new_revision,
          content_markdown: result[:content],
          actor_type: ApiToken::HOLDER_TYPE,
          actor_id: @api_token.id,
          change_summary: params[:change_summary],
          diff_unified: diff.presence,
          operations_json: result[:applied],
          base_revision: base_revision,
          reason: params[:reason]
        )

        @plan.update!(
          current_plan_version: version,
          current_revision: new_revision
        )

        @plan.comment_threads.where(out_of_date: false).where.not(plan_version_id: version.id).update_all(
          out_of_date: true,
          out_of_date_since_version_id: version.id
        )

        broadcast_plan_update

        render json: {
          revision: new_revision,
          content_sha256: version.content_sha256,
          applied: result[:applied].length,
          version_id: version.id
        }, status: :created

      rescue Plans::OperationError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue EditLease::Conflict => e
        render json: { error: e.message }, status: :conflict
      end

      private

      def broadcast_plan_update
        Turbo::StreamsChannel.broadcast_replace_to(
          @plan,
          target: "plan-header",
          partial: "plans/header",
          locals: { plan: @plan }
        )
      end
    end
  end
end
