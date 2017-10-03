module TaxonomyParser
  module PresentationParser

    def parse_presentation_linkbases

      @id = 1
      files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xml")

      Dir.glob(files).grep_v(/minimum/).grep(/presentation/) do |file|
        Nokogiri::XML(File.open(file))
      end.flat_map do |parsed_file|
        parsed_file.xpath("//xmlns:presentationLink")
      end.tap do |presentation_links|
        populate_presentation_graph(presentation_links)
      end
    end

    def populate_presentation_graph(presentation_links)

      # set up a node store namespace, a node index scoped to role for parent lookups and a base id.
      links = {}
      @store[:presentation_nodes] = {}
      
      # Parse all presentation links scoped by role_type
      presentation_links.each do |link|
        role_id = link.attributes["role"].value
        links[role_id] ||= {}
        role = @store[:role_types].values.find { |i| i.role_uri == role_id }
        
        # Locs (pointers to concepts) can be used to populate the nodes in the graph.
        link.search("loc").each do |loc|
          element_id = loc.attributes["label"].value
          href = loc.attributes["href"].value

          # Within a role_type there are no duplicate locs. 
          if links[role_id][element_id].nil?
            element = @store[:elements][element_id]
            model = PresentationNode.new(@id, role, element, href)
            role.presentation_nodes << model
            element.presentation_nodes << model
            
            @store[:presentation_nodes][model.id] = model
            links[role_id][element_id] = model
            @id += 1
          end
        end
      end

      # Join nodes separately or else extensions might attempt to look up locs 
      # that point to nodes that haven't been created yet.
      presentation_links.each do |link|
        role_id = link.attributes["role"].value
        role = @store[:role_types].values.find { |i| i.role_uri == role_id }
        link.search("presentationArc").each do |arc|
          parent_loc_id = arc.attributes["from"].value
          child_loc_id = arc.attributes["to"].value
          model = links[role_id][child_loc_id]

          if model.parent
            model = presentation_node_alias(model)
            role.presentation_nodes << model
          end

          model.parent = links[role_id][parent_loc_id]
          model.order = arc.attributes["order"].value
        end
      end
    end

    def presentation_node_alias(model)
      # e.g. xlink:label="uk-bus_MeansContactHeading" has two parent links with same role.
      @id += 1
      model_alias = model.dup
      model_alias.id = @id
      @store[:presentation_nodes][@id] = model_alias
      model_alias
    end
  end
end