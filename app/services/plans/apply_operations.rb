module Plans
  class ApplyOperations
    def self.call(content:, operations:)
      new(content:, operations:).call
    end

    def initialize(content:, operations:)
      @content = content.dup
      @operations = operations
      @applied = []
    end

    def call
      @operations.each_with_index do |op, index|
        op = op.transform_keys(&:to_s)
        case op["op"]
        when "replace_exact"
          apply_replace_exact(op, index)
        when "insert_under_heading"
          apply_insert_under_heading(op, index)
        when "delete_paragraph_containing"
          apply_delete_paragraph_containing(op, index)
        else
          raise OperationError, "Operation #{index}: unknown op '#{op["op"]}'"
        end
        @applied << op
      end

      { content: @content, applied: @applied }
    end

    private

    def apply_replace_exact(op, index)
      old_text = op["old_text"]
      new_text = op["new_text"]
      count = (op["count"] || 1).to_i

      raise OperationError, "Operation #{index}: replace_exact requires 'old_text'" if old_text.blank?
      raise OperationError, "Operation #{index}: replace_exact requires 'new_text'" if new_text.nil?

      occurrences = @content.scan(old_text).length

      if occurrences == 0
        raise OperationError, "Operation #{index}: replace_exact found 0 occurrences of the specified text"
      end

      if occurrences > count
        raise OperationError, "Operation #{index}: replace_exact found #{occurrences} occurrences, expected at most #{count}"
      end

      if count == 1
        @content = @content.sub(old_text, new_text)
      else
        @content = @content.gsub(old_text, new_text)
      end
    end

    def apply_insert_under_heading(op, index)
      heading = op["heading"]
      content_to_insert = op["content"]

      raise OperationError, "Operation #{index}: insert_under_heading requires 'heading'" if heading.blank?
      raise OperationError, "Operation #{index}: insert_under_heading requires 'content'" if content_to_insert.nil?

      pattern = /^#{Regexp.escape(heading)}\s*$/
      matches = @content.scan(pattern)

      if matches.length == 0
        raise OperationError, "Operation #{index}: insert_under_heading found no heading matching '#{heading}'"
      end

      if matches.length > 1
        raise OperationError, "Operation #{index}: insert_under_heading found #{matches.length} headings matching '#{heading}'"
      end

      @content = @content.sub(pattern) do |match|
        "#{match}\n#{content_to_insert}"
      end
    end

    def apply_delete_paragraph_containing(op, index)
      needle = op["needle"]

      raise OperationError, "Operation #{index}: delete_paragraph_containing requires 'needle'" if needle.blank?

      paragraphs = @content.split(/\n{2,}/)
      matching = paragraphs.each_index.select { |i| paragraphs[i].include?(needle) }

      if matching.length == 0
        raise OperationError, "Operation #{index}: delete_paragraph_containing found no paragraph containing '#{needle}'"
      end

      if matching.length > 1
        raise OperationError, "Operation #{index}: delete_paragraph_containing found #{matching.length} paragraphs containing '#{needle}'"
      end

      paragraphs.delete_at(matching.first)
      @content = paragraphs.join("\n\n")
    end
  end
end
