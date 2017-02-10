module PresentationParser

  Node = Struct.new(:id, :element_id, :parent_id, :role, :order)

  def parse_presentation_linkbases
    Dir.glob("dts_assets/uk-gaap/**/*").grep(/presentation.xml/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_links = parsed_file.xpath("//xmlns:presentationLink")
      populate_links(parsed_links)
      # nodes = parse_nodes(parsed_links)
      # construct_graph(parsed_links, nodes)
    end
  end

  def populate_links(links)
    links.each do |link|
      role = link.attributes["role"].value
      locs = {}
      @links[role] ||= {}
      node_ids = @links[role]
      link.search("loc", "presentationArc").each do |element|
        if element.name == "loc"
          locs[element.attributes["label"].value] = element.attributes["href"].value
        else
          find_parent_id(element, node_ids, role, locs)
        end
      end
    end
  end

  def find_parent_id(arc, node_ids, role, locs)
    parent_link = arc.attributes["from"].value
    child_link = arc.attributes["to"].value
    order = arc.attributes["order"].value
    parent_id = node_ids[parent_link] || create_node(parent_link, nil, role, node_ids).id
    create_node(child_link, parent_id, role, node_ids, order)
  end

  def create_node(element_id, parent_id, role, node_ids, order = "0")
    node = Node.new(
      SecureRandom.uuid,
      element_id,
      parent_id,
      role,
      order
    )
    node_ids[node.element_id] ||= node.id
    @nodes[node.id] = node.to_h
    node
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
      check[:arcs][:xml] += link.xpath("./xmlns:presentationArc").count
      link.xpath("./xmlns:presentationArc").each do |arc|
        link_nodes(arc, locators)
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
