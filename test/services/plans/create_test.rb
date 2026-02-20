require "test_helper"

class Plans::CreateTest < ActiveSupport::TestCase
  test "creates plan with initial version" do
    user = users(:alice)
    plan = Plans::Create.call(
      title: "New Plan",
      content: "# New Plan\n\nSome content.",
      user: user
    )

    assert plan.persisted?
    assert_equal "New Plan", plan.title
    assert_equal "brainstorm", plan.status
    assert_equal user, plan.created_by_user
    assert_equal user.organization, plan.organization
    assert_equal 1, plan.current_revision
    assert_equal 1, plan.plan_versions.count

    version = plan.current_plan_version
    assert_equal "# New Plan\n\nSome content.", version.content_markdown
    assert_equal 1, version.revision
    assert_equal "human", version.actor_type
    assert_equal user.id, version.actor_id
    assert version.content_sha256.present?
  end
end
