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

    nodes = @test_obj.store[:presentation_nodes].values
    expected = "uk-bus_E-mailAddress"
    assert_equal 9036, nodes.size, "All nodes parsed"

    actual_grandparents = lookup_nodes("uk-bus_E-mailAddress").map { |node| node.parent.parent.element.id }.sort
    expected_grandparents = %w[
      uk-bus_EntityContactsWebsiteInformationHeading
      uk-bus_GeneralContactInformationHeading
      uk-bus_ThirdPartyAgentsHeading
    ]
    assert_equal 3, lookup_nodes("uk-bus_E-mailAddress").size, "create on extra alias"
    assert_equal expected_grandparents, actual_grandparents, "presentation tree being constructed correctly"
  end

  def lookup_nodes(element_id)
    @test_obj.store[:elements][element_id].presentation_nodes
  end
end