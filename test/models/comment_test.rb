require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "valid comment" do
    comment = comments(:thread_comment)
    assert comment.valid?
  end

  test "validates body_markdown presence" do
    comment = comments(:thread_comment)
    comment.body_markdown = ""
    assert_not comment.valid?
    assert_includes comment.errors[:body_markdown], "can't be blank"
  end

  test "validates author_type inclusion" do
    comment = comments(:thread_comment)
    comment.author_type = "unknown"
    assert_not comment.valid?
    assert_includes comment.errors[:author_type], "is not included in the list"
  end

  test "belongs to comment_thread" do
    comment = comments(:thread_comment)
    assert_equal comment_threads(:roadmap_thread), comment.comment_thread
  end
end
