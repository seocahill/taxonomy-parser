module PresentationParser

  Node = Struct.new(:id, :element_id, :href, :role, :parent_id, :order)

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
    id = 1
    
    # Parse all presentation links together scoping them by role_type

    presentation_links.each do |link|
      role_id = link.attributes["role"].value
      links[role_id] ||= {}
      role = @store[:role_types].values.find { |i| i.role_uri == role_id }
      if role.nil?
        binding.pry
      end
      
      # Within a role there are no duplicate locs. Locs are essentialy the nodes in the graph.

      link.search("loc").each do |loc|
        element_id = loc.attributes["label"].value
        href = loc.attributes["href"].value
        # raise "#{links[role_id][element_id].inspect}" unless links[role_id][element_id].nil?
        if links[role_id][element_id].nil?
          node = Node.new(id, element_id, href, role)
          links[role_id][element_id] = node
          @nodes << node
          id += 1
        end
      end
    end

    #need to join nodes separately or else extensions might look up locs that haven't been created yet.

    presentation_links.each do |link|
      role = links[link.attributes["role"].value]
      link.search("presentationArc").each do |arc|
        parent_loc_id = arc.attributes["from"].value
        child_loc_id = arc.attributes["to"].value
        order = arc.attributes["order"].value
        node = role[child_loc_id]
        # if child_loc_id == "uk-bus_DimensionMembersIdentifyingTypeEntityOfficerHeading"
        if node.id == "43"
          binding.pry
        end
        node.parent_id = role[parent_loc_id]&.id
        node.order = order
      end
    end
  end

  # having built the graph we can now create the models to represent it.

  def parse_presentation_nodes
    bucket = @store[:presentation_nodes] = {}
    @nodes.each do |node|
      element = @store[:elements][node[:element_id]]
      model = PresentationNode.new(node.id, node.role, element, node.parent_id, node.order)
      node.role.presentation_nodes << model
      bucket[model.id] = model
    end
  end
end
