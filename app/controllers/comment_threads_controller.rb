class CommentThreadsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :scope_to_organization
  before_action :set_plan
  before_action :set_thread, only: [:resolve, :accept, :dismiss, :reopen]

  def create
    authorize!(@plan, :show?)

    thread = @plan.comment_threads.new(
      organization: @organization,
      plan_version: @plan.current_plan_version,
      anchor_text: params[:comment_thread][:anchor_text].presence,
      start_line: params[:comment_thread][:start_line].presence,
      end_line: params[:comment_thread][:end_line].presence,
      created_by_user: current_user
    )

    thread.save!

    comment = thread.comments.create!(
      organization: @organization,
      author_type: "human",
      author_id: current_user.id,
      body_markdown: params[:comment_thread][:body_markdown]
    )

    broadcast_new_thread(thread)
    redirect_to plan_path(@plan), notice: "Comment added."
  end

  def resolve
    authorize!(@thread, :resolve?)
    @thread.resolve!(current_user)
    broadcast_thread_update(@thread)
    redirect_to plan_path(@plan), notice: "Thread resolved."
  end

  def accept
    authorize!(@thread, :accept?)
    @thread.accept!(current_user)
    broadcast_thread_update(@thread)
    redirect_to plan_path(@plan), notice: "Thread accepted."
  end

  def dismiss
    authorize!(@thread, :dismiss?)
    @thread.dismiss!(current_user)
    broadcast_thread_update(@thread)
    redirect_to plan_path(@plan), notice: "Thread dismissed."
  end

  def reopen
    authorize!(@thread, :reopen?)
    @thread.update!(status: "open", resolved_by_user: nil)
    broadcast_thread_update(@thread)
    redirect_to plan_path(@plan), notice: "Thread reopened."
  end

  private

  def set_plan
    @plan = @organization.plans.find(params[:plan_id])
  end

  def set_thread
    @thread = @plan.comment_threads.find(params[:id])
  end

  def broadcast_new_thread(thread)
    Turbo::StreamsChannel.broadcast_prepend_to(
      @plan,
      target: "comment-threads",
      partial: "comment_threads/thread",
      locals: { thread: thread, plan: @plan }
    )
  end

  def broadcast_thread_update(thread)
    Turbo::StreamsChannel.broadcast_replace_to(
      @plan,
      target: dom_id(thread),
      partial: "comment_threads/thread",
      locals: { thread: thread, plan: @plan }
    )
  end
end
