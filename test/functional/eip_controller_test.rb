require 'test_helper'

class EipControllerTest < ActionController::TestCase
  test "should get get" do
    get :get
    assert_response :success
  end

  test "should get displayresult" do
    get :displayresult
    assert_response :success
  end

end
