require "test_helper"

class CommentThreadTest < ActiveSupport::TestCase
  test "valid comment thread" do
    thread = comment_threads(:roadmap_thread)
    assert thread.valid?
  end

  test "validates status inclusion" do
    thread = comment_threads(:roadmap_thread)
    thread.status = "invalid"
    assert_not thread.valid?
    assert_includes thread.errors[:status], "is not included in the list"
  end

  test "line_specific? returns true when lines set" do
    thread = comment_threads(:general_thread)
    thread.start_line = 5
    thread.end_line = 8
    assert thread.line_specific?
  end

  test "line_specific? returns false for general thread" do
    thread = comment_threads(:general_thread)
    assert_not thread.line_specific?
  end

  test "line_range_text for range" do
    thread = comment_threads(:general_thread)
    thread.start_line = 5
    thread.end_line = 8
    assert_equal "Lines 5–8", thread.line_range_text
  end

  test "line_range_text for single line" do
    thread = comment_threads(:general_thread)
    thread.start_line = 5
    thread.end_line = 5
    assert_equal "Line 5", thread.line_range_text
  end

  test "line_range_text for general thread" do
    thread = comment_threads(:general_thread)
    assert_nil thread.line_range_text
  end

  test "resolve! sets status and user" do
    thread = comment_threads(:roadmap_thread)
    user = users(:alice)
    thread.resolve!(user)
    assert_equal "resolved", thread.status
    assert_equal user, thread.resolved_by_user
  end

  test "accept! sets status and user" do
    thread = comment_threads(:roadmap_thread)
    user = users(:alice)
    thread.accept!(user)
    assert_equal "accepted", thread.status
    assert_equal user, thread.resolved_by_user
  end

  test "dismiss! sets status and user" do
    thread = comment_threads(:roadmap_thread)
    user = users(:alice)
    thread.dismiss!(user)
    assert_equal "dismissed", thread.status
    assert_equal user, thread.resolved_by_user
  end

  test "open_threads scope" do
    plan = plans(:acme_roadmap)
    open = plan.comment_threads.open_threads
    assert open.all? { |t| t.status == "open" }
  end

  test "anchored? returns true when anchor_text set" do
    thread = comment_threads(:roadmap_thread)
    assert thread.anchored?
  end

  test "anchored? returns false when anchor_text blank" do
    thread = comment_threads(:general_thread)
    assert_not thread.anchored?
  end

  test "anchor_preview truncates long text" do
    thread = comment_threads(:roadmap_thread)
    thread.anchor_text = "a" * 100
    assert_equal "a" * 80 + "…", thread.anchor_preview
  end

  test "anchor_preview returns short text as-is" do
    thread = comment_threads(:roadmap_thread)
    thread.anchor_text = "short text"
    assert_equal "short text", thread.anchor_preview
  end
end
