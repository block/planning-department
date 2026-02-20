class AddAnchorTextToCommentThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :comment_threads, :anchor_text, :text, null: true
  end
end
