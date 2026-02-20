class CreatePlanVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_versions, id: :uuid do |t|
      t.references :plan, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.integer :revision, null: false
      t.text :content_markdown, null: false
      t.string :content_sha256, null: false
      t.text :diff_unified
      t.text :change_summary
      t.text :reason

      # Provenance
      t.string :actor_type, null: false
      t.string :actor_id, limit: 36

      # AI metadata
      t.string :ai_provider
      t.string :ai_model
      t.text :prompt_excerpt

      # Operation trace
      t.json :operations_json
      t.integer :base_revision

      t.timestamp :created_at, null: false
    end

    add_index :plan_versions, [:plan_id, :revision], unique: true
    add_index :plan_versions, [:plan_id, :created_at]

    add_foreign_key :plans, :plan_versions, column: :current_plan_version_id
  end
end
