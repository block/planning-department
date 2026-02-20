require "test_helper"

class Api::V1::LeasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { "Authorization" => "Bearer test-token-alice" }
    @plan = plans(:acme_roadmap)
  end

  test "acquire lease" do
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "my-token", body["lease_token"]
    assert body["expires_at"].present?
  end

  test "acquire lease generates token if not provided" do
    post api_v1_plan_lease_path(@plan), headers: @headers, as: :json
    assert_response :created
    body = JSON.parse(response.body)
    assert body["lease_token"].present?
  end

  test "acquire lease conflicts when held by another" do
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "first-token" },
      headers: @headers,
      as: :json
    assert_response :created

    bob_headers = { "Authorization" => "Bearer test-token-bob" }
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "second-token" },
      headers: bob_headers,
      as: :json
    assert_response :conflict
  end

  test "renew lease" do
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json
    assert_response :created

    patch api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json
    assert_response :success
  end

  test "renew lease with wrong token" do
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json

    patch api_v1_plan_lease_path(@plan),
      params: { lease_token: "wrong-token" },
      headers: @headers,
      as: :json
    assert_response :conflict
  end

  test "release lease" do
    post api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json

    delete api_v1_plan_lease_path(@plan),
      params: { lease_token: "my-token" },
      headers: @headers,
      as: :json
    assert_response :no_content
    assert_nil EditLease.find_by(plan_id: @plan.id)
  end
end
