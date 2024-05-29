require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get searches_create_url
    assert_response :success
  end
end
