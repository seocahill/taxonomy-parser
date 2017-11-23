require_relative './test_helper'
require 'ostruct'

class DimensionParserTest < MiniTest::Test
  include TaxonomyParser::TestHelper

  def setup
    @parser = TaxonomyParser::DimensionParser
    dts = OpenStruct.new(id: 1, name: "ie-gaap")
    elements = TaxonomyParser::Store.instance.get_data[:elements] = {}
    elements["uk-bus_NameEntityOfficer"] = OpenStruct.new(dimension_nodes: [])
    @parser.parse(dts)
  end

  def test_address_line_1_dimensions
    expected = ["uk-bus_DimensionsParent-EntityContactInfo", "uk-bus_DimensionsParent-ThirdPartyAgents"]
    assert_equal @parser.find_grouping_items("uk-bus_AddressLine1"), expected, "Address item has two grouping items"
  end

  def test_address_line_1_hypercubes
    expected = ["uk-bus_EntityContactInfoHypercube", "uk-bus_ThirdPartyAgentsHypercube"]
    actual = [
      "uk-bus_DimensionsParent-EntityContactInfo", 
      "uk-bus_DimensionsParent-ThirdPartyAgents"
    ].flat_map { |id|  @parser.find_grouping_item_hypercubes(id) }.map(&:element_id)
    assert_equal actual, expected, "Address element has two hypercubes"
  end

  def test_date_directors_signing_report_dimensions
    expected = ["uk-gaap_ItemsInheritingBasicDimensions", "uk-bus_DimensionsParent-NoDimensions"]
    actual = @parser.find_grouping_items("uk-direp_DateSigningDirectorsReport")
    assert_empty expected - actual, "Address item has two hypercubes"
  end

  def test_find_dimensions_grouping_items
    tfa_expected = ["uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions"]
    eo_expected = ["uk-bus_DimensionsParent-EntityOfficers"]
    assert_equal @parser.find_grouping_items("uk-gaap_TangibleFixedAssets"), tfa_expected, "find dimension grouping for Fixed Assets"
    assert_equal @parser.find_grouping_items("uk-gaap_DescriptionEffectSpecificRevisionToUsefulLifeTangibleFixedAssets"), tfa_expected, "find dimension grouping for Fixed Assets specific policy"
    assert_equal @parser.find_grouping_items("uk-bus_NameEntityOfficer"), eo_expected, "find dimension grouping for Name Entity Officer"
    assert_equal @parser.find_grouping_items("uk-direp_FeesDirectors"), eo_expected, "find dimension grouping for Fees Directors"
    assert_equal @parser.find_grouping_items("uk-direp_FeesDirectors"), eo_expected, "find dimension grouping for Fees Directors"
  end

  def test_find_hypercubes_of_grouping_item
    fixed_asset_hcubes =  @parser.find_grouping_item_hypercubes("uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions").map(&:element_id)
    assert_equal fixed_asset_hcubes, ["uk-gaap_TangibleFixedAssetsHypercube"], "find hypercubes for Fixed Assets"
    entity_officer_hcube = @parser.find_grouping_item_hypercubes("uk-bus_DimensionsParent-EntityOfficers").map(&:element_id)
    assert_equal entity_officer_hcube, ["uk-bus_EntityOfficersHypercube"], "find hypercubes for Entity officers"
  end

  def test_find_all_hypercube_dimensions
    fixed_assets_dimensions = %w[
      uk-gaap_TangibleFixedAssetClassesDimension
      uk-gaap_TangibleFixedAssetOwnershipDimension
      uk-gaap_RestatementsDimension
      uk-gaap_GroupCompanyDimension
    ]
    actual =  @parser.find_hypercube_dimensions("uk-gaap_TangibleFixedAssetsHypercube").map(&:element_id)
    assert_equal actual, fixed_assets_dimensions, "find all dimensions for Fixed Assets hypercube"
  end

  def test_find_dimension_default
    assert_equal @parser.find_dimension_default("uk-gaap_TangibleFixedAssetClassesDimension").element_id, "uk-gaap_AllTangibleFixedAssetsDefault", "find dimension default for Fixed Asset classes"
    assert_nil @parser.find_dimension_default("uk-bus_EntityOfficersDimension")&.element_id, "Entity Officer Dimension has no default"
  end

  def test_find_dimension_domains
    domains =  @parser.find_dimension_domains("uk-bus_EntityOfficersDimension").map(&:element_id)
    assert_equal domains, ["uk-bus_AllEntityOfficers"], "find domains for Entity Officer dimension"
  end

  def test_find_address_1_dimension_domains
    domains =  @parser.find_dimension_domains("uk-countries_CountriesDimension").map(&:element_id)
    assert_equal domains, ["uk-countries_DimensionMembersRepresentingCountriesRegionsHeading"], "find domains for Countries dimension"
  end

  def test_find_country_dimension_domain_members
    expected = "uk-countries_AllCountries"
    expected_child = "uk-countries_Afghanistan"
    start_node = OpenStruct.new(element_id: "uk-countries_DimensionMembersRepresentingCountriesRegionsHeading")
    actual = @parser.find_domain_members([start_node]).map(&:element_id)
    assert_includes actual, expected, "find test domain member for countries"
    assert_includes actual, expected_child, "find nested domain member for countries"
  end

  def test_find_dimension_domain_members
    expected = %w[
      uk-bus_AllOrdinaryShares uk-bus_AllPreferenceShares
      uk-bus_OrdinaryShareClass1 uk-bus_PreferenceShareClass1
      uk-bus_OrdinaryShareClass2 uk-bus_PreferenceShareClass2
      uk-bus_OrdinaryShareClass3 uk-bus_PreferenceShareClass3
      uk-bus_OrdinaryShareClass4 uk-bus_PreferenceShareClass4
      uk-bus_OrdinaryShareClass5 uk-bus_PreferenceShareClass5
    ]
    start_node = OpenStruct.new(element_id: "uk-bus_AllShareClassesDefault")
    actual = @parser.find_domain_members([start_node]).map(&:element_id)
    assert_empty actual - expected, "find all domain members for Share Classes"
  end

  def test_dimension_node_tree
    @parser.add_dimension_information_elements
    expected = %w[
      uk-bus_EntityOfficersHypercube 
      uk-bus_EntityOfficersDimension uk-bus_EntityOfficerTypeDimension 
      uk-gaap_RestatementsDimension uk-gaap_GroupCompanyDimension
      uk-bus_AllEntityOfficers uk-bus_Director40
      uk-bus_Chairman uk-bus_CompanySecretaryDirector
      ie-common_Partner20 uk-bus_PartnerLLP20
    ]
    element = TaxonomyParser::Store.instance.get_data[:elements]["uk-bus_NameEntityOfficer"]
    actual = element.dimension_nodes.map(&:element_id)
    assert_empty (expected - actual), "Expected dimension nodes for Entity Officer Dimension"
    refute element.dimension_nodes.find { |node| node.element_id == "uk-bus_EntityOfficersHypercube"}.has_defaults, "Entity Officer hyperube has a dimension without a default value"

    # test parent child relationships are set correctly before serializing 
    dimension_ids = find_children("uk-bus_EntityOfficersHypercube", element.dimension_nodes).map(&:element_id)
    domain_ids = find_children("uk-bus_EntityOfficersDimension", element.dimension_nodes).map(&:element_id)
    member_ids = find_children("uk-bus_AllEntityOfficers", element.dimension_nodes).map(&:element_id)
    assert_includes dimension_ids, "uk-bus_EntityOfficersDimension", "find hypercube child"
    assert_includes domain_ids, "uk-bus_AllEntityOfficers", "find dimension domains"
    assert_includes member_ids, "ie-common_Partner20", "find domain members"
  end
end