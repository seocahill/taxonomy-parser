require_relative './test_helper'

class IeGaapTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  # This is important from a UX perspective. If a user selects a tag that has dimensions
  # without a default, that tag will be invalid unless the user selects a dimension for it.
  # The API needs to return a boolean indicating whether this is the case to the client.
  # Dimension nodes should also indictate which hypercube dimension requires the choice.
  # 

  def test_element_without_all_default_dimensions
    # uk-direp_FeesDirectors is a deeply nested item that also falls under Entity Officers Hypercube
    # get primary item
    # 
    get '/elements/uk-bus_NameEntityOfficer'
    assert_equal false, json_data["attributes"]["default-dimensions"], "Entity Officers Dimension has no default value"
  end

  def test_element_with_all_default_dimensions
    # uk-gaap_DescriptionDepreciationMethodRateOrUsefulEconomicLifeForTangibleFixedAssets
    skip "todo"
  end

  
end