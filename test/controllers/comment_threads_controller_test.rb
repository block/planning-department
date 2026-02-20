require "test_helper"

class CommentThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
    @plan = plans(:acme_roadmap)
  end

  test "create comment thread with anchor text" do
    assert_difference ["CommentThread.count", "Comment.count"], 1 do
      post plan_comment_threads_path(@plan), params: {
        comment_thread: {
          anchor_text: "world domination",
          body_markdown: "This needs work."
        }
      }
    end
    assert_redirected_to plan_path(@plan)
    thread = CommentThread.last
    assert_equal "world domination", thread.anchor_text
    assert_equal "open", thread.status
    assert_equal @plan.current_plan_version_id, thread.plan_version_id
  end

  test "create general comment thread" do
    assert_difference "CommentThread.count", 1 do
      post plan_comment_threads_path(@plan), params: {
        comment_thread: {
          body_markdown: "General feedback."
        }
      }
    end
    thread = CommentThread.last
    assert_nil thread.anchor_text
  end

  test "resolve thread" do
    thread = comment_threads(:roadmap_thread)
    patch resolve_plan_comment_thread_path(@plan, thread)
    assert_redirected_to plan_path(@plan)
    thread.reload
    assert_equal "resolved", thread.status
  end

  test "accept thread as plan author" do
    thread = comment_threads(:roadmap_thread)
    patch accept_plan_comment_thread_path(@plan, thread)
    thread.reload
    assert_equal "accepted", thread.status
  end

  test "dismiss thread as plan author" do
    thread = comment_threads(:roadmap_thread)
    patch dismiss_plan_comment_thread_path(@plan, thread)
    thread.reload
    assert_equal "dismissed", thread.status
  end

  test "reopen resolved thread" do
    thread = comment_threads(:roadmap_thread)
    thread.resolve!(users(:alice))
    patch reopen_plan_comment_thread_path(@plan, thread)
    thread.reload
    assert_equal "open", thread.status
    assert_nil thread.resolved_by_user_id
  end

  test "non-author cannot accept thread" do
    sign_in_as users(:bob)
    thread = comment_threads(:roadmap_thread)
    patch accept_plan_comment_thread_path(@plan, thread)
    assert_response :not_found
    thread.reload
    assert_equal "open", thread.status
  end
end
