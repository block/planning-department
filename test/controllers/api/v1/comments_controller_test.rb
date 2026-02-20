require "test_helper"

class Api::V1::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = { "Authorization" => "Bearer test-token-alice" }
    @plan = plans(:acme_roadmap)
  end

  test "create comment thread" do
    assert_difference ["CommentThread.count", "Comment.count"], 1 do
      post api_v1_plan_comments_path(@plan),
        params: {
          body_markdown: "API comment here",
          start_line: 1,
          end_line: 3
        },
        headers: @headers,
        as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert body["thread_id"].present?
    assert body["comment_id"].present?
  end

  test "create general comment thread" do
    assert_difference "CommentThread.count", 1 do
      post api_v1_plan_comments_path(@plan),
        params: { body_markdown: "General API feedback" },
        headers: @headers,
        as: :json
    end
    assert_response :created
  end

  test "reply to thread" do
    thread = comment_threads(:roadmap_thread)
    assert_difference "Comment.count", 1 do
      post reply_api_v1_plan_comment_path(@plan, thread),
        params: { body_markdown: "API reply" },
        headers: @headers,
        as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal thread.id, body["thread_id"]
  end

  test "reply to nonexistent thread" do
    post reply_api_v1_plan_comment_path(@plan, "nonexistent-id"),
      params: { body_markdown: "Reply" },
      headers: @headers,
      as: :json
    assert_response :not_found
  end

  test "create comment requires auth" do
    post api_v1_plan_comments_path(@plan),
      params: { body_markdown: "No auth" },
      as: :json
    assert_response :unauthorized
  end
end
