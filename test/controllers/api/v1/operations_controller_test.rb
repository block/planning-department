require "test_helper"

class Api::V1::OperationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { "Authorization" => "Bearer test-token-alice" }
    @plan = plans(:acme_roadmap)
    @lease_token = SecureRandom.hex(32)
    EditLease.acquire!(
      plan: @plan,
      holder_type: "local_agent",
      holder_id: api_tokens(:alice_token).id,
      lease_token: @lease_token
    )
  end

  test "apply operations creates new version" do
    assert_difference "PlanVersion.count", 1 do
      post api_v1_plan_operations_path(@plan),
        params: {
          lease_token: @lease_token,
          base_revision: @plan.current_revision,
          operations: [
            { op: "replace_exact", old_text: "world domination", new_text: "success", count: 1 }
          ]
        },
        headers: @headers,
        as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @plan.current_revision + 1, body["revision"]
  end

  test "apply operations fails without lease" do
    EditLease.find_by(plan_id: @plan.id)&.destroy

    post api_v1_plan_operations_path(@plan),
      params: {
        lease_token: "no-lease",
        base_revision: @plan.current_revision,
        operations: [{ op: "replace_exact", old_text: "x", new_text: "y", count: 1 }]
      },
      headers: @headers,
      as: :json
    assert_response :conflict
  end

  test "apply operations fails on stale revision" do
    post api_v1_plan_operations_path(@plan),
      params: {
        lease_token: @lease_token,
        base_revision: 999,
        operations: [{ op: "replace_exact", old_text: "x", new_text: "y", count: 1 }]
      },
      headers: @headers,
      as: :json
    assert_response :conflict
  end

  test "apply operations fails on invalid operation" do
    post api_v1_plan_operations_path(@plan),
      params: {
        lease_token: @lease_token,
        base_revision: @plan.current_revision,
        operations: [{ op: "replace_exact", old_text: "nonexistent text", new_text: "y", count: 1 }]
      },
      headers: @headers,
      as: :json
    assert_response :unprocessable_entity
  end

  test "apply operations requires lease_token" do
    post api_v1_plan_operations_path(@plan),
      params: {
        base_revision: @plan.current_revision,
        operations: [{ op: "replace_exact", old_text: "x", new_text: "y", count: 1 }]
      },
      headers: @headers,
      as: :json
    assert_response :unprocessable_entity
  end
end
