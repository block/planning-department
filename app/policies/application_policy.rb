class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def admin?
    user.admin?
  end

  def same_organization?
    record.respond_to?(:organization_id) && record.organization_id == user.organization_id
  end
end
