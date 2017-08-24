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
end