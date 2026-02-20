require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "index shows plans" do
    get plans_path
    assert_response :success
    assert_select ".plans-list__title", "Acme Roadmap"
  end

  test "index filters by status" do
    get plans_path(status: "considering")
    assert_response :success
    assert_select ".plans-list__title", "Acme Roadmap"
  end

  test "show plan renders markdown by default" do
    get plan_path(plans(:acme_roadmap))
    assert_response :success
    assert_select "h1", "Acme Roadmap"
    assert_select ".markdown-rendered"
  end

  test "show plan displays comments sidebar" do
    get plan_path(plans(:acme_roadmap))
    assert_response :success
    assert_select ".comment-threads-list"
  end

  test "show plan includes turbo stream subscription" do
    get plan_path(plans(:acme_roadmap))
    assert_response :success
    assert_select "turbo-cable-stream-source"
  end

  test "edit plan" do
    get edit_plan_path(plans(:acme_roadmap))
    assert_response :success
  end

  test "update plan creates new version" do
    plan = plans(:acme_roadmap)
    assert_difference "PlanVersion.count", 1 do
      patch plan_path(plan), params: {
        plan: { title: "Updated Title", content_markdown: "# Updated", change_summary: "Revised" }
      }
    end
    plan.reload
    assert_equal "Updated Title", plan.title
    assert_equal 2, plan.current_revision
    assert_redirected_to plan_path(plan)
  end

  test "cannot view brainstorm plan as non-author" do
    sign_in_as users(:bob)
    get plan_path(plans(:brainstorm_plan))
    assert_response :not_found
  end

  test "update marks existing threads as out of date" do
    plan = plans(:acme_roadmap)
    thread = comment_threads(:roadmap_thread)
    assert_not thread.out_of_date?

    patch plan_path(plan), params: {
      plan: { title: plan.title, content_markdown: "# Updated content", change_summary: "Updated" }
    }

    thread.reload
    assert thread.out_of_date?
    assert_not_nil thread.out_of_date_since_version_id
  end
end
