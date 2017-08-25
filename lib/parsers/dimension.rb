module DimensionParser

  def parse_definition_linkbases
    @def_linkbases = Dir.glob(File.join(__dir__, "/../../dts_assets/#{@current_dts.name}/**/*")).grep(/definition.xml/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
    end
    generate_dimension_indices
  end

  def generate_dimension_indices
    @def_index = {}
    @def_linkbases.each do |linkbase|
      linkbase.search('definitionArc').each do |def_arc|
        arcrole = def_arc.attributes["arcrole"].value
        to = def_arc.attributes["to"].value
        from = def_arc.attributes["from"].value
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

  def dimension_node_tree(element_id)
    grouping_item_id = find_dimensions_grouping_item(element_id)
    hypercubes = find_grouping_item_hypercubes(grouping_item_id)
    hypercube_dimensions = hypercubes.flat_map { |id| find_hypercube_dimensions(id) }
    default_dimensions = hypercube_dimensions.map { |id| find_dimension_default(id) }
    dimension_domains = hypercube_dimensions.flat_map { |id| find_dimension_domains(id) }
    all_domain_members = dimension_domains.flat_map { |id| find_all_domain_members(id) }
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
