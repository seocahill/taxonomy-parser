module TaxonomyParser
  module PresentationParser

    def parse_presentation_linkbases
      @parent_child_index = {}
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
            save_presentation_model(model)
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
          parent = links[role_id][parent_loc_id]

          if model.parent
            model = presentation_node_alias(role, model)
          end

          model.parent = parent
          model.order = arc.attributes["order"].value
          
          # update index
          @parent_child_index[parent.id] ||= []
          @parent_child_index[parent.id] << model.id
        end
      end
    end

    def presentation_node_alias(role, model)
      # e.g. xlink:label="uk-bus_MeansContactHeading" has two parent links with same role.
      @id += 1
      model_alias = model.dup
      model_alias.id = @id
      save_presentation_model(model_alias)

      # fill out the full subtree if the original model has children
      children = @store[:presentation_nodes].values_at(*@parent_child_index[model.id])
      if children.any?
        children.each do |child| 
          child_alias = presentation_node_alias(role, child) 
          child_alias.parent = model_alias
        end
      end

      model_alias
    end

    def save_presentation_model(model)
      # set up relationships and store
      model.role_type.presentation_nodes << model
      model.element.presentation_nodes << model
      @store[:presentation_nodes][model.id] = model
    end
  end
end