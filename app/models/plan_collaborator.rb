class PlanCollaborator < ApplicationRecord
  ROLES = %w[author reviewer viewer].freeze

  belongs_to :plan
  belongs_to :organization
  belongs_to :user
  belongs_to :added_by_user, class_name: "User", optional: true

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :plan_id }
end
