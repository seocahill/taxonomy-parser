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
    data[:elements]["uk-gaap_NameEntityOfficer"] = OpenStruct.new(dimension_nodes: [])
    data
  end

  def test_find_dimensions_grouping_items
    assert_equal @test_obj.find_dimensions_grouping_item("uk-gaap_TangibleFixedAssets"), "uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions", "find dimension grouping for Fixed Assets"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-gaap_DescriptionEffectSpecificRevisionToUsefulLifeTangibleFixedAssets"), "uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions", "find dimension grouping for Fixed Assets specific policy"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-bus_NameEntityOfficer"), "uk-bus_DimensionsParent-EntityOfficers", "find dimension grouping for Name Entity Officer"
    assert_equal @test_obj.find_dimensions_grouping_item("uk-direp_FeesDirectors"), "uk-bus_DimensionsParent-EntityOfficers", "find dimension grouping for Fees Directors"
  end

  def test_find_hypercubes_of_grouping_item
    assert_equal @test_obj.find_grouping_item_hypercubes("uk-gaap_ItemsInheritingTangibleFixedAssetsDimensions"), ["uk-gaap_TangibleFixedAssetsHypercube"], "find hypercubes for Fixed Assets"
    assert_equal @test_obj.find_grouping_item_hypercubes("uk-bus_DimensionsParent-EntityOfficers"), ["uk-bus_EntityOfficersHypercube"], "find hypercubes for Entity officers"
  end

  def test_find_all_hypercube_dimensions
    fixed_assets_dimensions = %w[
      uk-gaap_TangibleFixedAssetClassesDimension
      uk-gaap_TangibleFixedAssetOwnershipDimension
      uk-gaap_RestatementsDimension
      uk-gaap_GroupCompanyDimension
    ]
    assert_equal @test_obj.find_hypercube_dimensions("uk-gaap_TangibleFixedAssetsHypercube"), fixed_assets_dimensions, "find all dimensions for Fixed Assets hypercube"
  end

  def test_find_dimension_default
    assert_equal @test_obj.find_dimension_default("uk-gaap_TangibleFixedAssetClassesDimension"), "uk-gaap_AllTangibleFixedAssetsDefault", "find dimension default for Fixed Asset classes"
    assert_nil @test_obj.find_dimension_default("uk-bus_EntityOfficersDimension"), "Entity Officer Dimension has no default"
  end

  def test_find_dimension_domains
    assert_equal @test_obj.find_dimension_domains("uk-bus_EntityOfficersDimension"), ["uk-bus_AllEntityOfficers"], "find domains for Entity Officer dimension"
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
    actual = @test_obj.find_all_domain_members("uk-bus_AllShareClassesDefault")
    assert_empty actual - expected, "find all domain members for Share Classes"
  end

  def test_dimension_node_tree
    @test_obj.add_dimension_information_elements
    # test default
    # test hypercubes
    # test members
    skip
    assert_empty @test_obj.dimension_node_tree("uk-bus_NameEntityOfficer"), "whats in here?"
  end
end