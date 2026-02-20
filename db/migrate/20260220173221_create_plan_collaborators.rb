class CreatePlanCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_collaborators, id: :uuid do |t|
      t.references :plan, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :role, null: false
      t.references :added_by_user, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :plan_collaborators, [:plan_id, :user_id], unique: true
  end
end
