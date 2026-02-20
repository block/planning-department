class CommentThreadPolicy < ApplicationPolicy
  def create?
    same_organization?
  end

  def resolve?
    same_organization? && (record.created_by_user_id == user.id || record.plan.created_by_user_id == user.id)
  end

  def accept?
    same_organization? && record.plan.created_by_user_id == user.id
  end

  def dismiss?
    same_organization? && record.plan.created_by_user_id == user.id
  end

  def reopen?
    same_organization? && (record.created_by_user_id == user.id || record.plan.created_by_user_id == user.id)
  end
end
