require_relative './test_helper'

class DiscoverableTaxonomySetsTest < MiniTest::Test
  include Rack::Test::Methods
  include TaxonomyParser::TestHelper

  def app
    TaxonomyParser::Base
  end

  def test_element_dimension_nodes
    get '/elements/uk-bus_AddressLine1/dimension-nodes'
    assert last_response.ok?, "should be ok"
    nodes = json_data
    root_nodes = nodes.select { |node| node['relationships']['parent']['data'].nil? }
    expected_hypercubes = ["uk-bus_EntityContactInfoHypercube", "uk-bus_ThirdPartyAgentsHypercube"]
    actual = root_nodes.map { |node| node['relationships']['element']['data']['id'] }
    assert_empty expected - actual, "all roots correct and present"
    expected_dimensions = %w[
      uk-bus_EntityContactTypeDimension
      uk-gaap_GroupCompanyDimension
      uk-bus_FormContactDimension
      uk-bus_AddressTypeDimension
      uk-bus_PhoneNumberTypeDimension
      uk-countries_CountriesDimension
      uk-language_LanguagesDimension
    ]
  end
end