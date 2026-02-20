ActiveAdmin.register User do
  permit_params :organization_id, :email, :name, :org_role

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :org_role
    column :organization
    column :last_sign_in_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :org_role
      row :organization
      row :oidc_provider
      row :last_sign_in_at
      row :created_at
      row :updated_at
    end
  end
end
