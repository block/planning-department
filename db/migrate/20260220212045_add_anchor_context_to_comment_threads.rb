class AddAnchorContextToCommentThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :comment_threads, :anchor_context, :text
  end
end
