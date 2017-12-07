module TaxonomyParser
  class PresentationParser < BaseParser

    class << self

      def parse(current_dts)
        @id = 1
        @bucket = Store.instance.data[:presentation_nodes] = {}
        @current_dts = current_dts
        # some local indices required to build graph properly
        @parent_child_index = {}
        @role_elements_index = {}
        create_presentation_graph
      end
      
      def create_presentation_graph
        files = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*.xml")
        Dir.glob(files).grep_v(/minimum/).grep(/presentation/) do |file|
          Nokogiri::XML(File.open(file))
        end.flat_map do |parsed_file|
          parsed_file.xpath("//xmlns:presentationLink")
        end.tap do |presentation_links|
          parse_nodes(presentation_links)
          join_nodes(presentation_links)
        end
      end

      def parse_nodes(presentation_links)
        # Parse all presentation links scoped by role_type
        presentation_links.each do |link|
          role = lookup_role(link)
          @role_elements_index[role.id] ||= {}
          # Locs (pointers to concepts) can be used to populate the nodes in the graph.
          link.search("loc").each do |loc|
            element_id = loc.attributes["label"].value
            # Within a role_type there are no duplicate locs. 
            save_new_element(element_id, loc, role) if @role_elements_index[role.id][element_id].nil?
          end
        end
      end

      def join_nodes(presentation_links)
        # Join nodes separately or else extensions might attempt to look up locs 
        # that point to nodes that haven't been created yet.
        presentation_links.each do |link|
          role = lookup_role(link)
          link.search("presentationArc").each do |arc|
            parent_loc_id = arc.attributes["from"].value
            child_loc_id = arc.attributes["to"].value
            model = @role_elements_index[role.id][child_loc_id]
            parent = @role_elements_index[role.id][parent_loc_id]

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

      private

      def lookup_role(link)
        role_id = index(:role_uri)[link.attributes["role"].value]
        Store.instance.data[:role_types][role_id]
      end

      def lookup_children(model)
        @bucket.values_at(*@parent_child_index[model.id])
      end

      def presentation_node_alias(role, model)
        # e.g. xlink:label="uk-bus_MeansContactHeading" has two parent @role_elements_index with same role.
        @id += 1
        model_alias = model.dup
        model_alias.id = @id
        save_presentation_model(model_alias)

        # fill out the full subtree if the original model has children
        children = lookup_children(model)
        if children.any?
          children.each do |child| 
            child_alias = presentation_node_alias(role, child) 
            child_alias.parent = model_alias
          end
        end
        model_alias
      end

      def save_new_element(element_id, loc, role)
        element = Store.instance.data[:elements][element_id]
        href = loc.attributes["href"].value
        model = PresentationNode.new(@id, role, element, href)
        save_presentation_model(model)
        @role_elements_index[role.id][element_id] = model
        @id += 1
      end

      def save_presentation_model(model)
        # set up relationships and store
        model.role_type.presentation_nodes << model
        model.element.presentation_nodes << model
        @bucket[model.id] = model
      end
    end
  end
end