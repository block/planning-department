require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
    @plan = plans(:acme_roadmap)
    @thread = comment_threads(:roadmap_thread)
  end

  test "create reply" do
    assert_difference "Comment.count", 1 do
      post plan_comment_thread_comments_path(@plan, @thread), params: {
        comment: { body_markdown: "I agree with this." }
      }
    end
    assert_redirected_to plan_path(@plan)
    comment = Comment.last
    assert_equal "human", comment.author_type
    assert_equal users(:alice).id, comment.author_id
  end
end
