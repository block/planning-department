require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "sign in page renders" do
    get sign_in_path
    assert_response :success
    assert_select "input[name=email]"
  end

  test "sign in with valid email creates session" do
    post sign_in_path, params: { email: "alice@acme.com" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select ".site-nav__user", /Alice/
  end

  test "sign in with unknown domain shows error" do
    post sign_in_path, params: { email: "user@unknown.com" }
    assert_response :unprocessable_entity
    assert_select ".flash--alert", /No organization found/
  end

  test "sign in creates new user if not exists" do
    assert_difference "User.count", 1 do
      post sign_in_path, params: { email: "newuser@acme.com" }
    end
    assert_redirected_to root_path
  end

  test "sign out clears session" do
    post sign_in_path, params: { email: "alice@acme.com" }
    delete sign_out_path
    assert_redirected_to sign_in_path

    get root_path
    assert_redirected_to sign_in_path
  end

  test "unauthenticated access redirects to sign in" do
    get root_path
    assert_redirected_to sign_in_path
  end
end
