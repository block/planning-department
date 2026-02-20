class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments, id: :uuid do |t|
      t.column :comment_thread_id, :uuid, null: false
      t.column :organization_id, :uuid, null: false
      t.string :author_type, null: false
      t.column :author_id, :uuid, null: true
      t.text :body_markdown, null: false
      t.timestamps
    end

    add_index :comments, [:comment_thread_id, :created_at]
    add_foreign_key :comments, :comment_threads
    add_foreign_key :comments, :organizations
  end
end
