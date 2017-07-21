module PresentationParser

  Node = Struct.new(:id, :element_id, :parent_id, :role_id, :order)

  def parse_presentation_linkbases
    Dir.glob(File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xml")).grep_v(/minimum/).grep(/presentation/) do |file|
      Nokogiri::XML(File.open(file))
    end.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:presentationLink")
    end.tap do |presentation_links|
      populate_links(presentation_links)
    end
  end

  def populate_links(presentation_links)
    links = {}
    # gather all presentation links together by role_type
    # then parse them
    presentation_links.each do |link|
      role = link.attributes["role"].value
      locs = {}
      links[role] ||= {}
      node_ids = links[role]
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
    id = @nodes.keys.any? ? (@nodes.keys[-1] + 1) : 1
    node = Node.new(id, element_id, parent_id, role, order)
    node_ids[node.element_id] ||= node.id
    @nodes[node.id] = node.to_h
    node
  end

  def parse_presentation_nodes
    bucket = @store[:presentation_nodes] = {}
    @nodes.values.each do |node|
      # if node[:element_id] == "ie-common_PartnersPartnershipHeading"
      if node[:element_id] == "uk-bus_DimensionMembersIdentifyingPositionEntityOfficerHeading"
        binding.pry
      end
      parent = bucket[node[:parent_id]]
      element = @store[:elements][node[:element_id]]
      role = @store[:role_types].values.find { |i| i.role_uri == node[:role_id] }
      model = PresentationNode.new(node[:id], role.id, element, parent, node[:order])
      (role.presentation_nodes ||= []) << model
      bucket[model.id] = model
    end
  end
end
