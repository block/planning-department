require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "valid token" do
    token = api_tokens(:alice_token)
    assert token.valid?
  end

  test "requires name" do
    token = ApiToken.new(organization: organizations(:acme), user: users(:alice), token_digest: "abc123")
    token.name = nil
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "requires token_digest" do
    token = ApiToken.new(organization: organizations(:acme), user: users(:alice), name: "Test")
    token.token_digest = nil
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  test "authenticate with valid token" do
    result = ApiToken.authenticate("test-token-alice")
    assert_not_nil result
    assert_equal api_tokens(:alice_token).id, result.id
  end

  test "authenticate with invalid token" do
    result = ApiToken.authenticate("invalid-token")
    assert_nil result
  end

  test "authenticate with revoked token returns nil" do
    result = ApiToken.authenticate("test-token-revoked")
    assert_nil result
  end

  test "authenticate with blank token returns nil" do
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end

  test "revoke sets revoked_at" do
    token = api_tokens(:alice_token)
    assert_not token.revoked?
    token.revoke!
    assert token.revoked?
    assert_not_nil token.revoked_at
  end

  test "active? returns false when revoked" do
    token = api_tokens(:revoked_token)
    assert_not token.active?
  end

  test "active? returns true for valid token" do
    token = api_tokens(:alice_token)
    assert token.active?
  end

  test "generate_token returns hex string" do
    raw = ApiToken.generate_token
    assert_match /\A[0-9a-f]{64}\z/, raw
  end
end
