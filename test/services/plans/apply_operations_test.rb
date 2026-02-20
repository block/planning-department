require "test_helper"

class Plans::ApplyOperationsTest < ActiveSupport::TestCase
  test "replace_exact replaces text" do
    result = Plans::ApplyOperations.call(
      content: "Hello world, hello universe.",
      operations: [{ "op" => "replace_exact", "old_text" => "world", "new_text" => "planet", "count" => 1 }]
    )
    assert_equal "Hello planet, hello universe.", result[:content]
    assert_equal 1, result[:applied].length
  end

  test "replace_exact with count 2 replaces all occurrences" do
    result = Plans::ApplyOperations.call(
      content: "foo bar foo baz",
      operations: [{ "op" => "replace_exact", "old_text" => "foo", "new_text" => "qux", "count" => 2 }]
    )
    assert_equal "qux bar qux baz", result[:content]
  end

  test "replace_exact fails when text not found" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "Hello world",
        operations: [{ "op" => "replace_exact", "old_text" => "missing", "new_text" => "found", "count" => 1 }]
      )
    end
    assert_match /found 0 occurrences/, error.message
  end

  test "replace_exact fails when too many occurrences" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "foo foo foo",
        operations: [{ "op" => "replace_exact", "old_text" => "foo", "new_text" => "bar", "count" => 1 }]
      )
    end
    assert_match /found 3 occurrences/, error.message
  end

  test "replace_exact requires old_text" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "Hello",
        operations: [{ "op" => "replace_exact", "new_text" => "Bye" }]
      )
    end
    assert_match /requires 'old_text'/, error.message
  end

  test "insert_under_heading inserts content" do
    content = "# Title\n\nIntro\n\n## Goals\n\nExisting goals."
    result = Plans::ApplyOperations.call(
      content: content,
      operations: [{ "op" => "insert_under_heading", "heading" => "## Goals", "content" => "- New goal" }]
    )
    assert_includes result[:content], "## Goals\n\n- New goal"
    assert_includes result[:content], "Existing goals."
  end

  test "insert_under_heading fails when heading not found" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "# Title\n\nContent",
        operations: [{ "op" => "insert_under_heading", "heading" => "## Missing", "content" => "stuff" }]
      )
    end
    assert_match /no heading matching/, error.message
  end

  test "insert_under_heading fails when heading is ambiguous" do
    content = "## Goals\n\nFirst\n\n## Goals\n\nSecond"
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: content,
        operations: [{ "op" => "insert_under_heading", "heading" => "## Goals", "content" => "stuff" }]
      )
    end
    assert_match /found 2 headings/, error.message
  end

  test "delete_paragraph_containing removes paragraph" do
    content = "First paragraph.\n\nThis is deprecated.\n\nThird paragraph."
    result = Plans::ApplyOperations.call(
      content: content,
      operations: [{ "op" => "delete_paragraph_containing", "needle" => "deprecated" }]
    )
    assert_equal "First paragraph.\n\nThird paragraph.", result[:content]
    assert_not_includes result[:content], "deprecated"
  end

  test "delete_paragraph_containing fails when not found" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "Some content.",
        operations: [{ "op" => "delete_paragraph_containing", "needle" => "missing" }]
      )
    end
    assert_match /no paragraph containing/, error.message
  end

  test "delete_paragraph_containing fails when ambiguous" do
    content = "First deprecated thing.\n\nSecond deprecated thing."
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: content,
        operations: [{ "op" => "delete_paragraph_containing", "needle" => "deprecated" }]
      )
    end
    assert_match /found 2 paragraphs/, error.message
  end

  test "unknown operation raises error" do
    error = assert_raises(Plans::OperationError) do
      Plans::ApplyOperations.call(
        content: "Hello",
        operations: [{ "op" => "unknown_op" }]
      )
    end
    assert_match /unknown op/, error.message
  end

  test "multiple operations applied sequentially" do
    content = "# Plan\n\n## Phase 1\n\nDo stuff.\n\n## Phase 2\n\nOld approach."
    result = Plans::ApplyOperations.call(
      content: content,
      operations: [
        { "op" => "replace_exact", "old_text" => "Do stuff.", "new_text" => "Do important stuff.", "count" => 1 },
        { "op" => "insert_under_heading", "heading" => "## Phase 2", "content" => "\n- New step" }
      ]
    )
    assert_includes result[:content], "Do important stuff."
    assert_includes result[:content], "- New step"
    assert_equal 2, result[:applied].length
  end

  test "operations with string keys work" do
    result = Plans::ApplyOperations.call(
      content: "Hello world",
      operations: [{ "op" => "replace_exact", "old_text" => "world", "new_text" => "planet", "count" => 1 }]
    )
    assert_equal "Hello planet", result[:content]
  end

  test "operations with symbol keys work" do
    result = Plans::ApplyOperations.call(
      content: "Hello world",
      operations: [{ op: "replace_exact", old_text: "world", new_text: "planet", count: 1 }]
    )
    assert_equal "Hello planet", result[:content]
  end
end
