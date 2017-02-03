module PresentationParser

  def parse_definition_and_presentation_linkbases
    Dir.glob("dts_assets/uk-gaap/**/*").grep(/(definition.xml|presentation.xml)/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_links = parsed_file.xpath("//*[self::xmlns:definitionLink or self::xmlns:presentationLink]")
      nodes = parse_nodes(parsed_links)
      construct_graph(parsed_links, nodes)
    end
    add_tree_locations_to_all_nodes
  end

  def parse_nodes(links)
    entries = {}
    links.each do |link|
      role = link.attributes["role"].value
      locators = entries[role] ||= {}
      check = @checksums[role] ||= {}
      check[:locs] ||= { xml: 0 }
      check[:locs][:xml] += link.xpath("./xmlns:loc").count
      link.xpath("./xmlns:loc").each do |loc|
        locs = @links[role][:locs] ||= {}
        locs[loc.attributes['href'].value] = hashify_xml(loc)
        build_node_properties(loc, locators)
      end
    end
    entries
  end

  def build_node_properties(loc, locators)
    href = loc.attributes['href'].value
    locators[loc.attributes['label'].value] = {
      href: href,
      label: node_labels(href),
      reference: node_references(href),
      properties: @concepts[href.split("#").last]
    }
  end

  def node_labels(href)
    loc_label = @label_items[:locs][href.split("#").last]["label"]
    link_to = @label_items[:links][loc_label]["to"]
    label = @label_items[:resources][link_to]["http://www.xbrl.org/2003/role/label"]
  end

  def node_references(href)
    reference = "This concept does not have any references."
    loc_ref = @reference_items[:locs].dig(href.split("#").last, "label")
    if loc_ref
      ref_link_to = @reference_items[:links][loc_ref]["to"]
      reference = @reference_items[:resources][ref_link_to]
    end
  end

  def construct_graph(parsed_links, nodes)
    parsed_links.each do |link|
      role = link.attributes["role"].value
      locators = nodes[role]
      check = @checksums[role] ||= {}
      check[:arcs] ||= { xml: 0 }
      check[:arcs][:xml] += link.xpath("./*[self::xmlns:definitionArc or self::xmlns:presentationArc]").count
      link.xpath("./*[self::xmlns:definitionArc or self::xmlns:presentationArc]").each do |arc|
        link_nodes(arc, locators)
        arcs = @links[role][:arcs] ||= {}
        id = arc.attributes["from"].value + "/" + arc.attributes["to"].value
        arcs[id] = hashify_xml(arc)
      end

      @networks[role] = {
        label: @role_types[role]["definition"],
        networks: locators.values.map { |i| i[:arcrole]&.split("/")&.last }.compact.uniq,
        nodes: node_tree(locators, role)
      }
    end
  end

  def link_nodes(arc, locators)
    from_loc = locators[arc.attributes["from"].value]
    from_loc[:arcrole] = arc.attributes["arcrole"]&.value if from_loc
    to_loc = locators[arc.attributes["to"].value]
    if to_loc
      tree_locs = @network_locations[arc.attributes["to"].value] ||= Set.new
      tree_locs << Hash[arc.attributes["arcrole"]&.value, arc.attributes["from"]&.value]
      to_loc[:parent] = arc.attributes["from"]&.value
      to_loc[:order] = arc.attributes["order"]&.value
      to_loc[:arcrole] ||= arc.attributes["arcrole"]&.value
    end
  end

  def node_tree(locators, role)
    root_nodes = locators.reject do |k,v|
      v.has_key?(:parent)
    end

    root_nodes.each do |k,v|
      @network_locations[k] ||= Set.new
      @network_locations[k] << Hash[role, "root_node"]
      v[:children] = children_for_node(locators, k)
    end
  end

  def children_for_node(locators, k)
    children = locators.select { |a,b| b[:parent] == k }
    children.each do |a,b|
      b[:children] = children_for_node(locators, a)
    end
  end

  def add_tree_locations_to_all_nodes
    @networks.each do |k,v|
      v[:nodes].each do |a,b|
        add_tree_locations_to_node(a, b)
      end
    end
    @networks
  end

  def add_tree_locations_to_node(key, value)
    value[:tree_locations] = @network_locations[key]&.to_a #|| Hash[value[:arcrole], "root_node"]
    value[:children].each do |k,v|
      add_tree_locations_to_node(k, v)
    end
  end
end