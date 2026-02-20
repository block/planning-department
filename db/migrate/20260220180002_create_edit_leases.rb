class CreateEditLeases < ActiveRecord::Migration[8.1]
  def change
    create_table :edit_leases, id: :uuid do |t|
      t.column :plan_id, :uuid, null: false
      t.column :organization_id, :uuid, null: false
      t.string :holder_type, null: false
      t.column :holder_id, :uuid
      t.string :lease_token_digest, null: false
      t.timestamp :expires_at, null: false
      t.timestamp :last_heartbeat_at, null: false
      t.timestamps
    end

    add_index :edit_leases, :plan_id, unique: true
    add_foreign_key :edit_leases, :plans
    add_foreign_key :edit_leases, :organizations
  end
end
