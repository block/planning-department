require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  test "render_markdown converts markdown to HTML" do
    html = render_markdown("# Hello\n\n**bold** text")
    assert_includes html, "<h1>"
    assert_includes html, "<strong>bold</strong>"
    assert_includes html, "markdown-rendered"
  end

  test "render_markdown sanitizes dangerous HTML" do
    html = render_markdown('<script>alert("xss")</script>')
    assert_no_match(/<script>/, html)
  end

  test "render_markdown handles nil gracefully" do
    html = render_markdown(nil)
    assert_includes html, "markdown-rendered"
  end

  test "render_line_view creates numbered divs" do
    html = render_line_view("line one\nline two\nline three")
    assert_includes html, 'id="L1"'
    assert_includes html, 'id="L2"'
    assert_includes html, 'id="L3"'
    assert_includes html, 'data-line="1"'
    assert_includes html, 'data-line="3"'
    assert_includes html, "line-view"
  end

  test "render_line_view handles empty lines" do
    html = render_line_view("line one\n\nline three")
    assert_includes html, 'id="L2"'
    assert_includes html, "&nbsp;"
  end

  test "render_line_view escapes HTML in content" do
    html = render_line_view('<script>alert("xss")</script>')
    assert_no_match(/<script>/, html)
    assert_includes html, "&lt;script&gt;"
  end
end
