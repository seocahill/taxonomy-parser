module TaxonomyParser
  module DimensionParser

    def parse_definition_linkbases
      parse_definition_files
      generate_dimension_indices
      add_dimension_information_elements
    end

    def parse_definition_files
      path = File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*")
      @def_linkbases = Dir.glob(path).grep(/definition.xml/) do |file|
        parsed_file = Nokogiri::XML(File.open(file))
      end
    end

    def generate_dimension_indices
      @id = 0
      @store[:dimension_nodes] = {}
      @def_index = {}
      @def_linkbases.each do |linkbase|
        linkbase.search('definitionArc').each do |def_arc|
          arcrole = def_arc.attributes["arcrole"].value
          from = def_arc.attributes["from"].value
          to = def_arc.attributes["to"].value # order refers to this
          order = def_arc.attributes["order"]&.value || "0"
          @def_index[arcrole] ||= { to: {}, from: {} }
          if to
            @def_index[arcrole][:to][to] = from
          end
          if from
            model = add_dimension_node(element_id: to, order: order, arcrole: arcrole)
            (@def_index[arcrole][:from][from] ||= []) << model
          end
        end
      end
    end

    def add_dimension_information_elements
      @store[:elements].each do |id, element|
        element.dimension_nodes = dimension_node_tree(id, element)
      end
    end

    def dimension_node_tree(element_id, element)
      grouping_item_id = find_dimensions_grouping_item(element_id)
      nodes = []
      if hypercubes = find_grouping_item_hypercubes(grouping_item_id)
        hypercubes.each do |hypercube|
          # this is the root collection parent is nil
          nodes << hypercube

          # can have empty hypercubes e.g. uk-bus_EmptyHypercube
          if dimensions = find_hypercube_dimensions(hypercube.element_id)
            dimensions.each do |dimension|
              # create dimension and link to parent hypercube
              nodes << dimension
              dimension.parent = hypercube

              # check for defaults and update dimension if present
              dimension.default = find_dimension_default(dimension.element_id)

              find_dimension_domains(dimension.element_id).each do |domain|
                # create domain set dimension to parent
                nodes << domain
                domain.parent = dimension

                find_all_domain_members(domain).each do |member|
                  # create member with domain as parent
                  nodes << member
                  member.parent = domain
                end
              end
            end
            
            # Indicate if hypercube is covered by defaults
            if dimensions.any? { |node| node.default.nil? }
              hypercube.has_defaults = false
              element.must_choose_dimension = true
            end
          end
        end
      end
      nodes
    end

    def add_dimension_node(element_id:, parent: nil, order:, arcrole:)
      @id += 1
      model = DimensionNode.new(id: @id, element_id: element_id, parent: parent, arcrole: arcrole, order: order)
      @store[:dimension_nodes][@id] = model
      model
    end

    def find_dimensions_grouping_item(element_id)
      return nil unless element_id
      arcrole = 'http://xbrl.org/int/dim/arcrole/domain-member'
      parent_id = @def_index[arcrole][:to][element_id]
      find_dimensions_grouping_item(parent_id) || parent_id
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
      @def_index[arcrole][:from][dimension_id]
    end

    def find_all_domain_members(domain)
      find_domain_members([domain]) - [domain]
    end

    def find_domain_members(domains)
      return [] unless domains
      arcrole = "http://xbrl.org/int/dim/arcrole/domain-member"
      domains.flat_map do |domain|
        children = @def_index[arcrole][:from][domain.element_id]
        [domain] + find_domain_members(children)
      end
    end
  end
end
