require_relative './test_helper'
require 'ostruct'

class DimensionParserTest < MiniTest::Test
  include TaxonomyParser::TestHelper

  def setup
    @test_obj = Object.new
    @test_obj.extend(DimensionParser)
    dts = OpenStruct.new(id: 1, name: "ie-gaap")
    @test_obj.instance_variable_set(:@current_dts, dts)
    @test_obj.instance_variable_set(:@store, store)
    @test_obj.parse_definition_files
    @test_obj.generate_dimension_indices
  end

  def store
    data = { elements: {} }
    data[:elements]["uk-bus_NameEntityOfficer"] = OpenStruct.new(dimension_nodes: [])
    data
  end

  def test_find_dimensions_grouping_items
    assert_equal @test_obj.find_dimensions_grouping_item("uk-gaap_TangibleFixedAssets"), "uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions", "find dimension grouping for Fixed Assets"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-gaap_DescriptionEffectSpecificRevisionToUsefulLifeTangibleFixedAssets"), "uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions", "find dimension grouping for Fixed Assets specific policy"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-bus_NameEntityOfficer"), "uk-bus_DimensionsParent-EntityOfficers", "find dimension grouping for Name Entity Officer"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-direp_FeesDirectors"), "uk-bus_DimensionsParent-EntityOfficers", "find dimension grouping for Fees Directors"
  end

  def test_find_hypercubes_of_grouping_item
    fixed_asset_hcubes =  @test_obj.find_grouping_item_hypercubes("uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions").map(&:element_id)
    assert_equal fixed_asset_hcubes, ["uk-gaap_TangibleFixedAssetsHypercube"], "find hypercubes for Fixed Assets"
    entity_officer_hcube = @test_obj.find_grouping_item_hypercubes("uk-bus_DimensionsParent-EntityOfficers").map(&:element_id)
    assert_equal entity_officer_hcube, ["uk-bus_EntityOfficersHypercube"], "find hypercubes for Entity officers"
  end

  def test_find_all_hypercube_dimensions
    fixed_assets_dimensions = %w[
      uk-gaap_TangibleFixedAssetClassesDimension
      uk-gaap_TangibleFixedAssetOwnershipDimension
      uk-gaap_RestatementsDimension
      uk-gaap_GroupCompanyDimension
    ]
    actual =  @test_obj.find_hypercube_dimensions("uk-gaap_TangibleFixedAssetsHypercube").map(&:element_id)
    assert_equal actual, fixed_assets_dimensions, "find all dimensions for Fixed Assets hypercube"
  end

  def test_find_dimension_default
    assert_equal @test_obj.find_dimension_default("uk-gaap_TangibleFixedAssetClassesDimension").element_id, "uk-gaap_AllTangibleFixedAssetsDefault", "find dimension default for Fixed Asset classes"
    assert_nil @test_obj.find_dimension_default("uk-bus_EntityOfficersDimension")&.element_id, "Entity Officer Dimension has no default"
  end

  def test_find_dimension_domains
    domains =  @test_obj.find_dimension_domains("uk-bus_EntityOfficersDimension").map(&:element_id)
    assert_equal domains, ["uk-bus_AllEntityOfficers"], "find domains for Entity Officer dimension"
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
    actual = @test_obj.find_all_domain_members(start_node).map(&:element_id)
    assert_empty actual - expected, "find all domain members for Share Classes"
  end

  def test_dimension_node_tree
    @test_obj.add_dimension_information_elements
    expected = %w[
      uk-bus_EntityOfficersHypercube 
      uk-bus_EntityOfficersDimension uk-bus_EntityOfficerTypeDimension 
      uk-gaap_RestatementsDimension uk-gaap_GroupCompanyDimension
      uk-bus_AllEntityOfficers uk-bus_Director40
      uk-bus_Chairman uk-bus_CompanySecretaryDirector
      ie-common_Partner20 uk-bus_PartnerLLP20
    ]
    element = @test_obj.instance_variable_get(:@store)[:elements]["uk-bus_NameEntityOfficer"]
    actual = element.dimension_nodes.map(&:element_id)
    assert_empty (expected - actual), "Expected dimension nodes for Entity Officer Dimension"
    refute element.dimension_nodes.find { |node| node.element_id == "uk-bus_EntityOfficersHypercube"}.has_defaults, "Entity Officer hyperube has a dimension without a default value"
  end
end