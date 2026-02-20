class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.json :allowed_email_domains
      t.text :slack_webhook_url

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
  end
end
