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
    # log_response
    nodes = json_data

    # test hypercubes lookup
    hypercubes = nodes.select { |node| node['relationships']['parent']['data'].nil? }
    expected = ["uk-bus_EntityContactInfoHypercube", "uk-bus_ThirdPartyAgentsHypercube"]
    actual = hypercubes.map { |node| node['relationships']['element']['data']['id'] }
    assert_empty expected - actual, "all hypercubes correct and present"

    # test entity dimensions
    entity_hcube_id = hypercubes.first["id"]
    entity_hcube_dimensions = nodes.select { |node| node.dig('relationships', 'parent', 'data', 'id') == entity_hcube_id }
    actual = entity_hcube_dimensions.map { |node| node.dig('relationships', 'element', 'data', 'id') }
    expected = %w[
      uk-bus_EntityContactTypeDimension
      uk-gaap_GroupCompanyDimension
      uk-bus_FormContactDimension
      uk-bus_AddressTypeDimension
      uk-bus_PhoneNumberTypeDimension
      uk-countries_CountriesDimension
      uk-lang_LanguagesDimension
    ]
    assert_equal expected.sort, actual.sort, "all entity dimensions correct and present"

    # test third party dimensions
    third_party_hcube_id = hypercubes.last["id"]
    third_party_hcube_dimensions = nodes.select { |node| node.dig('relationships', 'parent', 'data', 'id') == third_party_hcube_id }
    actual = third_party_hcube_dimensions.map { |node| node.dig('relationships', 'element', 'data', 'id') }
    expected = %w[
      uk-bus_ThirdPartyAgentTypeDimension
      uk-bus_ThirdPartyAgentStatusDimension
      uk-bus_FormContactDimension
      uk-bus_AddressTypeDimension
      uk-bus_PhoneNumberTypeDimension
      uk-countries_CountriesDimension
      uk-lang_LanguagesDimension
      uk-gaap_GroupCompanyDimension
      uk-gaap_RestatementsDimension
    ]
    assert_equal expected.sort, actual.sort, "all third party dimensions correct and present"
  end
end