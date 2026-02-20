require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid organization" do
    org = organizations(:acme)
    assert org.valid?
  end

  test "requires name" do
    org = Organization.new(slug: "test", allowed_email_domains: ["test.com"])
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "requires slug" do
    org = Organization.new(name: "Test", allowed_email_domains: ["test.com"])
    assert_not org.valid?
    assert_includes org.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    org = Organization.new(name: "Duplicate", slug: "acme", allowed_email_domains: ["dup.com"])
    assert_not org.valid?
    assert_includes org.errors[:slug], "has already been taken"
  end

  test "slug format rejects uppercase" do
    org = Organization.new(name: "Test", slug: "BadSlug", allowed_email_domains: ["test.com"])
    assert_not org.valid?
    assert_includes org.errors[:slug], "only allows lowercase letters, numbers, and hyphens"
  end

  test "email_domain_allowed? returns true for allowed domain" do
    org = organizations(:acme)
    assert org.email_domain_allowed?("user@acme.com")
  end

  test "email_domain_allowed? returns false for disallowed domain" do
    org = organizations(:acme)
    assert_not org.email_domain_allowed?("user@other.com")
  end

  test "email_domain_allowed? is case-insensitive" do
    org = organizations(:acme)
    assert org.email_domain_allowed?("user@ACME.COM")
  end

  test "defaults allowed_email_domains to empty array" do
    org = Organization.new
    assert_equal [], org.allowed_email_domains
  end
end
