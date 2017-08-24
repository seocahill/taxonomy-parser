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

  def test_element_dimension_nodes
    get '/elements/uk-gaap_ShareCapitalAuthorised/dimension-nodes'
    assert last_response.ok?, "should be ok"
    assert_equal json_data.length, 125, "Dimension nodes for element"
  end

  def test_presentation_nodes
    id = Hash["id", "100,200,300"]
    params = Hash["filter", id]
    get '/presentation_nodes', params
    assert last_response.ok?, "should be ok"
    assert_equal 3, json_data.length, "should return 3 Presentation nodes."
  end

  def test_presentation_nodes
    get '/presentation_nodes/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "Loans for the purchase of own shares under Section 60 Companies Act 1963", "incorrect name"
    # assert json_includes("included", "name", node_names), "missing presentation nodes"
  end

  def test_dimension_nodes
    get '/elements/uk-gaap_ShareCapitalAuthorised'
    # get node
    get "/dimension_nodes/#{$app.store[:dimension_nodes].keys.first}"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "Shares [Hypercube]", "incorrect name"

    # get node element
    get "/dimension_nodes/#{$app.store[:dimension_nodes].keys.first}/element"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "SharesHypercube", "incorrect name"
  end
end