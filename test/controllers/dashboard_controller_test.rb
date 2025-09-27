require "test_helper"
  setup do
    @user = users(:one)
  end


class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    sign_in @user
    get dashboard_show_url
    assert_response :success
  end
end
