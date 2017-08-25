require_relative './test_helper'
require 'ostruct'

class DimensionParserTest < MiniTest::Test
  include TaxonomyParser::TestHelper

  def setup
    @test_obj = Object.new
    @test_obj.extend(DimensionParser)
    dts = OpenStruct.new(id: 1, name: "ie-gaap")
    @test_obj.instance_variable_set(:@current_dts, dts)
    @test_obj.parse_definition_linkbases
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

  def test_element_without_all_default_dimensions
    # uk-direp_FeesDirectors is a deeply nested item that also falls under Entity Officers Hypercube
    # get primary item
    # 
    skip "todo"
  end

  def test_element_with_all_default_dimensions
    # uk-gaap_DescriptionDepreciationMethodRateOrUsefulEconomicLifeForTangibleFixedAssets
    skip "todo"
  end

  
end