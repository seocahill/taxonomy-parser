require_relative './test_helper'

class IeGaapTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  def test_role_types
    id = Hash["id", "1,2,3"]
    params = Hash["filter", id]
    get '/role_types', params
    assert last_response.ok?, "should be ok"
    assert_equal 3, json_data.length, "should return 3 Role types"
  end

  def test_role_type
    get '/role_types/1'
    node_names = [
      "Entity information [heading]",
      "Date when ceased to be legal or registered name",
      "Irish VAT registration number",
      "Address line 1",
      "Receivers for entity"
    ]
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["definition"], "01 - Entity Information", "incorrect definition"
    assert json_includes("included", "name", node_names), "missing presentation nodes"
  end

  def test_element
    get '/elements/uk-gaap_ShareCapitalAuthorised'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "ShareCapitalAuthorised", "incorrect definition"
  end
end