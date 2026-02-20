class CommentsController < ApplicationController
  before_action :scope_to_organization
  before_action :set_plan
  before_action :set_thread

  def create
    authorize!(@plan, :show?)

    comment = @thread.comments.create!(
      organization: @organization,
      author_type: "human",
      author_id: current_user.id,
      body_markdown: params[:comment][:body_markdown]
    )

    Turbo::StreamsChannel.broadcast_append_to(
      @plan,
      target: ActionView::RecordIdentifier.dom_id(@thread, :comments),
      partial: "comments/comment",
      locals: { comment: comment }
    )

    redirect_to plan_path(@plan), notice: "Reply added."
  end

  private

  def set_plan
    @plan = @organization.plans.find(params[:plan_id])
  end

  def set_thread
    @thread = @plan.comment_threads.find(params[:comment_thread_id])
  end
end
