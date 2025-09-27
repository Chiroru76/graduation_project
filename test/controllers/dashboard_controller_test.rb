require "test_helper"



class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end
  test "should get show" do
    sign_in @user
    get dashboard_show_url
    assert_response :success
  end
end
