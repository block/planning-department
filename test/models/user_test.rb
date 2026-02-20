require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:alice)
    assert user.valid?
  end

  test "requires email" do
    user = User.new(organization: organizations(:acme), name: "Test", org_role: "member")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires name" do
    user = User.new(organization: organizations(:acme), email: "test@acme.com", org_role: "member")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "email must be unique within organization" do
    user = User.new(organization: organizations(:acme), email: "alice@acme.com", name: "Dup", org_role: "member")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "same email allowed in different orgs" do
    user = User.new(organization: organizations(:widgets), email: "alice@widgets.io", name: "Alice W", org_role: "member")
    assert user.valid?
  end

  test "org_role must be member or admin" do
    user = users(:alice)
    user.org_role = "superadmin"
    assert_not user.valid?
    assert_includes user.errors[:org_role], "is not included in the list"
  end

  test "admin? returns true for admin role" do
    assert users(:alice).admin?
  end

  test "admin? returns false for member role" do
    assert_not users(:bob).admin?
  end

  test "email domain must be allowed" do
    user = User.new(organization: organizations(:acme), email: "user@other.com", name: "Test", org_role: "member")
    assert_not user.valid?
    assert_includes user.errors[:email], "domain is not allowed for this organization"
  end

  test "email_domain extracts domain" do
    assert_equal "acme.com", users(:alice).email_domain
  end
end
