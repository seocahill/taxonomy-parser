require_relative './test_helper'

class PresentationParserTest < MiniTest::Test
  include TaxonomyParser::TestHelper

  def setup
    TaxonomyParser::ApplicationController.discoverable_taxonomy_set(1)
  end

  def test_email_nodes_are_created_properly
    # This is a test to check that various subtrees are create properly from the available linkage info.
    # The email tag exists in different roles and in different presentation sub-trees with the same role.
    # The taxonomy does not include separate locators and links for each email tag with the same role.
    # Rather has a series of parent nodes until the root of the subtree is reached whereupon it has two parents
    # "uk-bus_DimensionsParent-EntityContactInfo" and "uk-bus_DimensionsParent-ThirdPartyAgents". 
    # But rather than providing a link from each parent node to the same sub-tree it is preferable to attach
    # a copy of the subtree to each parent.

    nodes = TaxonomyParser::Store.instance.get_data[:presentation_nodes].values
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

  def test_tax_note_is_extended_correctly
    skip "The issue here is with the correct parsing of the IE extension and how it alters the base DTS"
    model = lookup_nodes("uk-gaap_TaxOnProfitOnOrdinaryActivitiesHeading").first
    children = @test_obj.lookup_children(model)
    assert_equal 6, children, "tax note heading has correct number of children"
  end
end