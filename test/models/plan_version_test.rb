require "test_helper"

class PlanVersionTest < ActiveSupport::TestCase
  test "valid version" do
    version = plan_versions(:roadmap_v1)
    assert version.valid?
  end

  test "computes sha256 automatically" do
    version = PlanVersion.new(
      plan: plans(:acme_roadmap),
      organization: organizations(:acme),
      revision: 99,
      content_markdown: "test content",
      actor_type: "human"
    )
    assert version.valid?
    assert_equal Digest::SHA256.hexdigest("test content"), version.content_sha256
  end

  test "revision must be unique per plan" do
    version = PlanVersion.new(
      plan: plans(:acme_roadmap),
      organization: organizations(:acme),
      revision: 1,
      content_markdown: "dupe",
      actor_type: "human"
    )
    assert_not version.valid?
    assert_includes version.errors[:revision], "has already been taken"
  end

  test "actor_type must be valid" do
    version = plan_versions(:roadmap_v1)
    version.actor_type = "robot"
    assert_not version.valid?
  end
end
