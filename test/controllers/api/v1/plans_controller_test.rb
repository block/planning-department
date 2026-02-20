require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { "Authorization" => "Bearer test-token-alice" }
  end

  test "index returns plans" do
    get api_v1_plans_path, headers: @headers
    assert_response :success
    plans = JSON.parse(response.body)
    assert plans.any? { |p| p["title"] == "Acme Roadmap" }
  end

  test "index excludes other org plans" do
    get api_v1_plans_path, headers: { "Authorization" => "Bearer test-token-carol" }
    assert_response :success
    plans = JSON.parse(response.body)
    assert_not plans.any? { |p| p["title"] == "Acme Roadmap" }
  end

  test "index requires auth" do
    get api_v1_plans_path
    assert_response :unauthorized
  end

  test "index with revoked token" do
    get api_v1_plans_path, headers: { "Authorization" => "Bearer test-token-revoked" }
    assert_response :unauthorized
  end

  test "show returns plan" do
    get api_v1_plan_path(plans(:acme_roadmap)), headers: @headers
    assert_response :success
    plan = JSON.parse(response.body)
    assert_equal "Acme Roadmap", plan["title"]
    assert plan["current_content"].present?
  end

  test "show returns 404 for other org plan" do
    get api_v1_plan_path(plans(:acme_roadmap)), headers: { "Authorization" => "Bearer test-token-carol" }
    assert_response :not_found
  end

  test "create creates new plan" do
    assert_difference "Plan.count", 1 do
      post api_v1_plans_path, params: { title: "API Plan", content: "# API Plan\n\nCreated via API." }, headers: @headers, as: :json
    end
    assert_response :created
    plan = JSON.parse(response.body)
    assert_equal "API Plan", plan["title"]
    assert_equal 1, plan["current_revision"]
  end

  test "create without title fails" do
    post api_v1_plans_path, params: { content: "no title" }, headers: @headers, as: :json
    assert_response :unprocessable_entity
  end

  test "versions returns version list" do
    get versions_api_v1_plan_path(plans(:acme_roadmap)), headers: @headers
    assert_response :success
    versions = JSON.parse(response.body)
    assert versions.any? { |v| v["revision"] == 1 }
  end

  test "comments returns thread list" do
    get comments_api_v1_plan_path(plans(:acme_roadmap)), headers: @headers
    assert_response :success
    threads = JSON.parse(response.body)
    assert threads.is_a?(Array)
  end
end
