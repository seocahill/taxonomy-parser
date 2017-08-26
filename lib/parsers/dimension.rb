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
          (@def_index[arcrole][:from][from] ||= []) << to
        end
      end
    end
  end

  def add_dimension_information_elements
    @store[:dimension_nodes] = {}
    @id = 0
    @store[:elements].each do |id, element|
      element.dimension_nodes = dimension_node_tree(id)
    end
  end

  def dimension_node_tree(element_id)
    grouping_item_id = find_dimensions_grouping_item(element_id)
    nodes = []
    if hypercubes = find_grouping_item_hypercubes(grouping_item_id)
      hypercubes.each do |hypercube_id|
        # this is the root collection parent is nil
        hypercube = add_dimension_node(hypercube_id)
        nodes << hypercube

        # can have empty hypercubes e.g. uk-bus_EmptyHypercube
        if dimensions = find_hypercube_dimensions(hypercube_id)
          dimensions.each do |dimension_id|
            # create dimension and link to parent hypercube
            dimension = add_dimension_node(dimension_id, hypercube)
            nodes << dimension
            hypercube.children << dimension

            # check for defaults and update dimension if present
            dimension.default_id = find_dimension_default(dimension_id)

            find_dimension_domains(dimension_id).each do |domain_id|
              # create domain set dimension to parent
              domain = add_dimension_node(domain_id, dimension)
              nodes << domain

              find_all_domain_members(domain_id).each do |member_id|
                # create member with domain as parent
                member = add_dimension_node(member_id, domain)
                nodes << member
              end
            end
          end
          
          # Indicate if hypercube is covered by defaults
          if hypercube.children.any? { |node| node.default_id.nil? }
            hypercube.has_defaults = false
          end
        end
      end
    end
    nodes
  end

  def add_dimension_node(element_id, parent = nil)
    @id += 1
    model = DimensionNode.new(@id, element_id, parent)
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

  def find_all_domain_members(domain_id)
    find_domain_members([domain_id]) - [domain_id]
  end

  def find_domain_members(domain_ids)
    return [] unless domain_ids
    arcrole = "http://xbrl.org/int/dim/arcrole/domain-member"
    domain_ids.flat_map do |id|
      child_ids = @def_index[arcrole][:from][id]
      [id] + find_domain_members(child_ids)
    end
  end
end
