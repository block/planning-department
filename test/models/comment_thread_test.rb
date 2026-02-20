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

  test "active scope returns open non-out-of-date threads" do
    plan = plans(:acme_roadmap)
    active = plan.comment_threads.active
    assert active.all? { |t| t.status == "open" && !t.out_of_date? }
  end

  test "active scope excludes resolved threads" do
    thread = comment_threads(:roadmap_thread)
    thread.resolve!(users(:alice))
    active = plans(:acme_roadmap).comment_threads.active
    assert_not active.include?(thread)
  end

  test "active scope excludes out-of-date threads" do
    thread = comment_threads(:roadmap_thread)
    thread.update_columns(out_of_date: true)
    active = plans(:acme_roadmap).comment_threads.active
    assert_not active.include?(thread)
  end

  test "archived scope returns non-open or out-of-date threads" do
    plan = plans(:acme_roadmap)
    archived = plan.comment_threads.archived
    assert archived.all? { |t| t.status != "open" || t.out_of_date? }
  end

  test "archived scope includes resolved threads" do
    thread = comment_threads(:roadmap_thread)
    thread.resolve!(users(:alice))
    archived = plans(:acme_roadmap).comment_threads.archived
    assert archived.include?(thread)
  end

  test "mark_out_of_date_for_new_version! keeps thread when anchor text still present" do
    plan = plans(:acme_roadmap)
    thread = comment_threads(:roadmap_thread)
    thread.update_columns(anchor_text: "world domination")

    new_version = PlanVersion.create!(
      plan: plan,
      organization: plan.organization,
      revision: 2,
      content_markdown: "# Acme Roadmap\n\nOur plan for world domination continues.",
      actor_type: "human",
      actor_id: users(:alice).id
    )

    plan.comment_threads.mark_out_of_date_for_new_version!(new_version)
    thread.reload
    assert_not thread.out_of_date?
  end

  test "mark_out_of_date_for_new_version! marks thread when anchor text removed" do
    plan = plans(:acme_roadmap)
    thread = comment_threads(:roadmap_thread)
    thread.update_columns(anchor_text: "world domination")

    new_version = PlanVersion.create!(
      plan: plan,
      organization: plan.organization,
      revision: 2,
      content_markdown: "# Acme Roadmap\n\nCompletely new content here.",
      actor_type: "human",
      actor_id: users(:alice).id
    )

    plan.comment_threads.mark_out_of_date_for_new_version!(new_version)
    thread.reload
    assert thread.out_of_date?
    assert_equal new_version.id, thread.out_of_date_since_version_id
  end

  test "mark_out_of_date_for_new_version! skips non-anchored threads" do
    plan = plans(:acme_roadmap)
    thread = comment_threads(:general_thread)

    new_version = PlanVersion.create!(
      plan: plan,
      organization: plan.organization,
      revision: 2,
      content_markdown: "Completely different content.",
      actor_type: "human",
      actor_id: users(:alice).id
    )

    plan.comment_threads.mark_out_of_date_for_new_version!(new_version)
    thread.reload
    assert_not thread.out_of_date?
  end

  test "mark_out_of_date_for_new_version! uses anchor_context when present" do
    plan = plans(:acme_roadmap)
    thread = comment_threads(:roadmap_thread)
    thread.update_columns(anchor_text: "plan", anchor_context: "Our plan for world domination")

    new_version = PlanVersion.create!(
      plan: plan,
      organization: plan.organization,
      revision: 2,
      content_markdown: "# Acme Roadmap\n\nWe have a plan but the context changed.",
      actor_type: "human",
      actor_id: users(:alice).id
    )

    plan.comment_threads.mark_out_of_date_for_new_version!(new_version)
    thread.reload
    assert thread.out_of_date?, "Thread should be out of date when anchor_context is no longer in content"
  end
end
