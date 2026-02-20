require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:alice)
  end

  test "index shows tokens" do
    get api_tokens_path
    assert_response :success
    assert_select "table.data-table"
  end

  test "create token shows raw token" do
    assert_difference "ApiToken.count", 1 do
      post api_tokens_path, params: { api_token: { name: "Test Token" } }
    end
    assert_response :success
    assert_select ".token-reveal"
    assert_select ".token-reveal__value code"
  end

  test "revoke token" do
    token = api_tokens(:alice_token)
    assert_not token.revoked?
    patch revoke_api_token_path(token)
    assert_redirected_to api_tokens_path
    token.reload
    assert token.revoked?
  end

  test "requires authentication" do
    delete sign_out_path
    get api_tokens_path
    assert_redirected_to sign_in_path
  end
end
