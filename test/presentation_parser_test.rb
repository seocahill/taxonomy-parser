require_relative './test_helper'
require 'ostruct'

class PresentationParserTest < MiniTest::Test
  include TaxonomyParser::TestHelper

  def setup
    @test_obj = TaxonomyParser::ApplicationController.new
  end

  def test_email_nodes_are_created_properly
    # This is a test to check that various subtrees are create properly from the available linkage info.
    # The email tag exists in different roles and in different presentation sub-trees with the same role.
    # The taxonomy does not include separate locators and links for each email tag with the same role.
    # Rather has a series of parent nodes until the root of the subtree is reached whereupon it has two parents
    # "uk-bus_DimensionsParent-EntityContactInfo" and "uk-bus_DimensionsParent-ThirdPartyAgents". 
    # But rather than providing a link from each parent node to the same sub-tree it is preferable to attach
    # a copy of the subtree to each parent. 
    expected = "uk-bus_E-mailAddress"
    assert_equal 7667, @test_obj.store[:presentation_nodes].size, "Sanity"
  end
end