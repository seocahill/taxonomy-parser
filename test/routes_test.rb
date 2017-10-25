require_relative './test_helper'
require 'logger'

class DiscoverableTaxonomySetsTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  def test_discoverable_taxonomy_sets
    get '/discoverable-taxonomy-sets'
    assert last_response.ok?, "should be ok"
    assert_equal 2, json_data.length, "should return 2 DTS"
    assert json_includes("name", ["ie-gaap", "uk-gaap"]), "should return correctd DTS data"
  end

  def test_discoverable_taxonomy_set
    get '/discoverable-taxonomy-sets/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "discoverable-taxonomy-sets"
    assert_equal 18, json_data("included").length, "should return all presentation role-types"
  end

  def test_role_types
    id = Hash["id", "1,2,3"]
    params = Hash["filter", id]
    get '/role-types', params
    assert last_response.ok?, "should be ok"
    assert_equal 3, json_data.length, "should return 3 Role types"
  end

  def test_role_type
    get '/role-types/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "role-types"
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
    get '/presentation-nodes', params
    assert last_response.ok?, "should be ok"
    assert_equal 3, json_data.length, "should return 3 Presentation nodes."
  end

  def test_presentation_node
    get '/presentation-nodes/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "presentation-nodes"
  end

  def test_dimension_nodes
    get "/dimension-nodes/1"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "dimension-nodes"

    # get node element
    get "/dimension-nodes/1/element"
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "elements"
  end

  def test_label
    get '/labels/1'
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "labels"
    assert json_data["attributes"].has_key?("label")
  end

  def test_reference
    get '/references/1'
    ref_data = [{"ISOName"=>"ISO 3166-1"}, {"Code"=>"AF"}, {"Date"=>"2009-09-01"}]
    assert last_response.ok?, "should be ok"
    assert_equal json_data["type"], "references"
    assert json_data["attributes"].has_key?("reference-data")
  end
end