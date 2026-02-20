class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :email, null: false
      t.string :name, null: false
      t.string :org_role, null: false, default: "member"
      t.string :oidc_provider
      t.string :oidc_sub
      t.timestamp :last_sign_in_at

      t.timestamps
    end

    add_index :users, [:organization_id, :email], unique: true
  end
end
