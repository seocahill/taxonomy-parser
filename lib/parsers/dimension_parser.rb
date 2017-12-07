module TaxonomyParser
  class DimensionParser

    class << self

      def parse(current_dts)
        @id = 1
        @current_dts = current_dts
        @def_index = {}
        @bucket = Store.instance.get_data[:dimension_nodes] = {}
        parse_definition_files
        generate_nodes_and_indices
        add_dimension_information_to_elements
      end

      def parse_definition_files
        path = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*")
        @def_linkbases = Dir.glob(path).grep(/definition.xml/) do |file|
          parsed_file = Nokogiri::XML(File.open(file))
        end
      end

      def generate_nodes_and_indices
        @def_linkbases.each do |linkbase|
          linkbase.search('definitionArc').each do |def_arc|
            index_parent_link(def_arc)
            create_and_index_node(def_arc)
          end
        end
      end

      def index_parent_link(def_arc)
        arcrole = def_arc.attributes["arcrole"].value
        @def_index[arcrole] ||= { to: {}, from: {} }
        if to = def_arc.attributes["to"].value
          (@def_index[arcrole][:to][to] ||= []) << def_arc.attributes["from"].value
        end
      end

      def create_and_index_node(def_arc)
        if from = def_arc.attributes["from"].value
          arcrole = def_arc.attributes["arcrole"].value
          order = def_arc.attributes["order"]&.value || "0"
          to = def_arc.attributes["to"].value
          model = add_dimension_node(element_id: to, order: order, arcrole: arcrole)
          (@def_index[arcrole][:from][from] ||= []) << model
        end
      end

      def add_dimension_information_to_elements
        Store.instance.get_data[:elements].each do |id, element|
          element.dimension_nodes = dimension_node_tree(id, element)
        end
      end

      def dimension_node_tree(element_id, element)
        @nodes = {}
        # tuples, dimension and hypercube nodes do not have dimensions
        if grouping_items = find_grouping_items(element_id)
          hypercubes = grouping_items.flat_map { |id| find_grouping_item_hypercubes(id) }
          if hypercubes.any?
            hypercubes.each do |hypercube|
              @nodes[hypercube.id] ||= hypercube
              add_hypercube_dimensions_to_nodes(hypercube, element)
            end
          end
        end
        @nodes.values
      end

      def add_hypercube_dimensions_to_nodes(hypercube, element)
        # can have empty hypercubes e.g. uk-bus_EmptyHypercube
        if dimensions = find_hypercube_dimensions(hypercube.element_id)
          dimensions.each do |dimension|
            # create dimension and link to parent hypercube
            @nodes[dimension.id] = dimension
            dimension.parent ||= hypercube 
            # check for defaults and update dimension if present
            dimension.default = find_dimension_default(dimension.element_id)
            add_dimension_domains_to_nodes(dimension)
          end
          # Indicate if hypercube is covered by defaults
          if dimensions.any? { |node| node.default.nil? }
            hypercube.has_defaults = false
            element.must_choose_dimension = true
          end
        end
      end

      def add_dimension_domains_to_nodes(dimension)
        find_dimension_domains(dimension.element_id).each do |domain|
          # create domain set dimension to parent
          if domain.parent && (domain.parent.parent.element_id != dimension.parent.element_id)
            domain = alias_dimension(domain)
          end
          domain.parent = dimension
          @nodes[domain.id] ||= domain 
          add_domain_members_to_nodes(domain)
        end
      end

      def add_domain_members_to_nodes(domain)
        find_domain_members([domain]).each do |member|
          # create member with domain as parent
          if member.parent
            member = alias_dimension(member)
          end
          member.parent = domain
          @nodes[member.id] ||= member
        end
      end

      def add_dimension_node(element_id:, parent: nil, order:, arcrole:)
        model = DimensionNode.new(id: @id, element_id: element_id, parent: parent, arcrole: arcrole, order: order)
        model.element = Store.instance.get_data[:elements][element_id]
        @bucket[@id] = model
        @id += 1
        model
      end

      def alias_dimension(model)
        node = model.dup
        node.id = @id
        @bucket[@id] = node
        @id += 1
        node
      end

      def find_grouping_items(element_id)
        arcrole = 'http://xbrl.org/int/dim/arcrole/domain-member'
        parents = @def_index[arcrole][:to][element_id]
        return nil unless parents
        parents.flat_map do |parent|
          find_grouping_items(parent) || parent
        end.compact.uniq
      end

      def find_grouping_item_hypercubes(grouping_item_id)
        arcrole = "http://xbrl.org/int/dim/arcrole/all"
        @def_index[arcrole][:from][grouping_item_id]
      end

      def find_hypercube_dimensions(hypercube_id)
        arcrole = "http://xbrl.org/int/dim/arcrole/hypercube-dimension"
        @def_index[arcrole][:from][hypercube_id]
      end

      def find_dimension_default(dimension_id)
        arcrole = "http://xbrl.org/int/dim/arcrole/dimension-default"
        @def_index[arcrole][:from][dimension_id]&.first
      end

      def find_dimension_domains(dimension_id)
        arcrole = "http://xbrl.org/int/dim/arcrole/dimension-domain"
        @def_index[arcrole][:from][dimension_id] || []
      end

      def find_domain_members(domains)
        return [] unless domains
        arcrole = "http://xbrl.org/int/dim/arcrole/domain-member"
        domains.flat_map do |domain|
          children = @def_index[arcrole][:from][domain.element_id]
          (domain.arcrole == arcrole) ? [domain] + find_domain_members(children) : find_domain_members(children)
        end
      end
    end
  end
end
