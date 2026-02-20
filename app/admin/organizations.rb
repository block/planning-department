ActiveAdmin.register Organization do
  permit_params :name, :slug, :slack_webhook_url, allowed_email_domains: []

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :allowed_email_domains
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :allowed_email_domains
      row :slack_webhook_url
      row :created_at
      row :updated_at
    end

    panel "Users" do
      table_for resource.users do
        column :id
        column :name
        column :email
        column :org_role
      end
    end
  end
end
