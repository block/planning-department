class CreateCommentThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_threads, id: :uuid do |t|
      t.column :plan_id, :uuid, null: false
      t.column :organization_id, :uuid, null: false
      t.column :plan_version_id, :uuid, null: false
      t.integer :start_line, null: true
      t.integer :end_line, null: true
      t.string :status, null: false, default: "open"
      t.boolean :out_of_date, null: false, default: false
      t.column :out_of_date_since_version_id, :uuid, null: true
      t.column :addressed_in_plan_version_id, :uuid, null: true
      t.column :created_by_user_id, :uuid, null: false
      t.column :resolved_by_user_id, :uuid, null: true
      t.timestamps
    end

    add_index :comment_threads, [:plan_id, :status]
    add_index :comment_threads, [:plan_id, :out_of_date]
    add_foreign_key :comment_threads, :plans
    add_foreign_key :comment_threads, :organizations
    add_foreign_key :comment_threads, :plan_versions
    add_foreign_key :comment_threads, :plan_versions, column: :out_of_date_since_version_id
    add_foreign_key :comment_threads, :plan_versions, column: :addressed_in_plan_version_id
    add_foreign_key :comment_threads, :users, column: :created_by_user_id
    add_foreign_key :comment_threads, :users, column: :resolved_by_user_id
  end
end
