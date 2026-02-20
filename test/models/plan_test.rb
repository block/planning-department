require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "valid plan" do
    plan = plans(:acme_roadmap)
    assert plan.valid?
  end

  test "requires title" do
    plan = Plan.new(organization: organizations(:acme), created_by_user: users(:alice))
    assert_not plan.valid?
    assert_includes plan.errors[:title], "can't be blank"
  end

  test "status must be valid" do
    plan = plans(:acme_roadmap)
    plan.status = "invalid"
    assert_not plan.valid?
  end

  test "defaults status to brainstorm" do
    plan = Plan.new
    assert_equal "brainstorm", plan.status
  end

  test "current_content returns version content" do
    plan = plans(:acme_roadmap)
    assert_includes plan.current_content, "Acme Roadmap"
  end

  test "to_param returns id" do
    plan = plans(:acme_roadmap)
    assert_equal plan.id, plan.to_param
  end
end
