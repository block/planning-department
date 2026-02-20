class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :status, null: false, default: "brainstorm"
      t.string :current_plan_version_id, limit: 36
      t.integer :current_revision, null: false, default: 0
      t.json :tags
      t.json :metadata
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :plans, [:organization_id, :status]
    add_index :plans, [:organization_id, :updated_at]
  end
end
