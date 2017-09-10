require_relative './test_helper'

class DiscoverableTaxonomySetsTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  def test_discoverable_taxonomy_sets
    get '/discoverable_taxonomy_sets'
    assert last_response.ok?, "should be ok"
    assert_equal 2, json_data.length, "should return 2 DTS"
    assert json_includes("name", ["ie-gaap", "uk-gaap"]), "should return correctd DTS data"
  end

  def test_discoverable_taxonomy_set
    get '/discoverable_taxonomy_sets/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "ie-gaap", "correct DTS"
    assert_equal 18, json_data("included").length, "should return all presentation role-types"
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
  end

  def test_element
    get '/elements/uk-gaap_ShareCapitalAuthorised'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "ShareCapitalAuthorised", "incorrect definition"
  end

  def test_element_dimension_nodes
    get '/elements/uk-gaap_ShareCapitalAuthorised/dimension-nodes'
    assert last_response.ok?, "should be ok"
    assert_equal json_data.length, 102, "Dimension nodes for element"
  end

  def test_presentation_nodes
    id = Hash["id", "100,200,300"]
    params = Hash["filter", id]
    get '/presentation_nodes', params
    assert last_response.ok?, "should be ok"
    assert_equal 3, json_data.length, "should return 3 Presentation nodes."
  end

  def test_presentation_node
    get '/presentation_nodes/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "Loans for the purchase of own shares under Section 60 Companies Act 1963", "incorrect name"
  end

  def test_dimension_nodes
    get "/dimension_nodes/1"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "Ireland", "incorrect name"

    # get node element
    get "/dimension_nodes/1/element"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["name"], "Ireland", "incorrect name"
  end

  def test_label
    get '/labels/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["label"], "Companies Registration Office number", "incorrect label"
  end

  def test_reference
    get '/references/1'
    ref_data = [{"ISOName"=>"ISO 3166-1"}, {"Code"=>"AF"}, {"Date"=>"2009-09-01"}]
    assert last_response.ok?, "should be ok"
    assert_equal json_data["attributes"]["reference-data"], ref_data, "incorrect reference data"
  end
end