require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @activated_user = users(:michael)
  end

  test 'invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name: '', email: 'user@invalid', password: 'foo', password_confirmation: 'bar' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert-danger'
  end

  test 'valid signup information with account activation' do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: 'Example User', email: 'user@example.com', password: 'password', password_confirmation: 'password' } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?

    # Unactivated user is not visible and users/:id redirected to root
    log_in_as(@activated_user)
    get users_path
    assert_select 'a[href=?]', user_path(@activated_user)
    assert_select 'a[href=?]', user_path(user), count: 0
    get user_path(user)
    follow_redirect!
    assert_template 'static_pages/home'
    log_out_as(@activated_user)

    log_in_as(user) # before activation
    assert_not is_logged_in?

    get edit_account_activation_path('invalid token', email: user.email) # invalid token
    assert_not is_logged_in?

    get edit_account_activation_path(user.activation_token, email: 'wrong') # wrong email
    assert_not is_logged_in?

    get edit_account_activation_path(user.activation_token, email: user.email) # valid information
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
    get users_path
    assert_select 'a[href=?]', user_path(user)
  end
end
