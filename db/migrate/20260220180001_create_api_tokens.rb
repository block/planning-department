class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens, id: :uuid do |t|
      t.column :organization_id, :uuid, null: false
      t.column :user_id, :uuid, null: false
      t.string :name, null: false
      t.string :token_digest, null: false
      t.timestamp :last_used_at
      t.timestamp :expires_at
      t.timestamp :revoked_at
      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, :user_id
    add_foreign_key :api_tokens, :organizations
    add_foreign_key :api_tokens, :users
  end
end
