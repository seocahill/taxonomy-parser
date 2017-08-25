module DimensionParser

  # Items inheriting basic dimensions

  Node = Struct.new(:id, :element_id, :parent_id, :order, :arcrole)

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

  def new_node(element, parent = nil, order = "1", arcrole)
    Node.new(SecureRandom.uuid, element, parent, order, arcrole)
  end

  def dimension_node_tree(concept_id)
    concept_node = new_node(concept_id, nil, "0", 'primary-item')
    nodes = find_primary_items(concept_node)
    bucket = @store[:dimension_nodes] = {}
    nodes.each do |node|
      parent = bucket[node[:parent_id]]
      element = @store[:elements][node[:element_id]]
      model = DimensionNode.new(node[:id], element, parent, node[:order], node[:arcrole])
      bucket[model.id] = model
    end
    bucket.values
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

  def find_domain_members(domain_id)
    return nil unless element_id
    arcrole = "http://xbrl.org/int/dim/arcrole/domain-member"
    member_ids = @def_index[arcrole][:from][domain_id]
    member_ids.flat_map do |id|
      find_domain_members(id)
    end.compact
  end

  def find_primary_items(concept_node)
    # you need to walk up the full tree not simply a matter of finding the parent and then the parents descendants
    search_results = {}
    items = @definitions.flat_map do |parsed_file|
      find_root_of_tree(parsed_file, concept_node.element_id, 'http://xbrl.org/int/dim/arcrole/domain-member')
    end
    nodes = items.flat_map do |item|
      node = new_node(item.attributes["from"].value, concept_node.id, item.attributes.dig("order")&.value, 'primary-item')
      find_hypercubes(node)
    end
    nodes
  end

  def find_root_of_tree(parsed_file, current_node, arcrole)
    current_node_id = current_node.is_a?(String) ? current_node : current_node.attributes["from"].value
    parents = parsed_file.xpath("//xmlns:definitionArc[@xlink:to='#{current_node_id}' and @xlink:arcrole='#{arcrole}']")
    if parents.any?
      parents.flat_map do |parent|
        find_root_of_tree(parsed_file, parent, arcrole)
      end
    else
      current_node.is_a?(Nokogiri::XML::Element) ? current_node : []
    end
  end

  def find_hypercubes(parent)
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/all']")
    end.uniq
    hypercubes = items.flat_map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value, item.attributes.dig('arcrole').value)
      [node.to_h] + find_dimensions(node)
    end
    hypercubes
  end

  def find_dimensions(parent)
    items = @definitions.flat_map do |parsed_file|
      parsed_file
      .xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/hypercube-dimension']")
    end
    dimensions = items.flat_map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value, item.attributes.dig('arcrole').value)
      [node.to_h] + find_domains(node)
    end
    dimensions
  end

  def find_domains(parent)
    arcroles = [
      "http://xbrl.org/int/dim/arcrole/dimension-default",
      "http://xbrl.org/int/dim/arcrole/dimension-domain"
    ]
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and contains('#{arcroles}', @xlink:arcrole)]")
    end
    domains = items.flat_map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value, item.attributes.dig('arcrole').value)
      [node.to_h] + find_domain_members(node)
    end
    domains
  end

  def find_domain_members(parent)
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/domain-member']")
    end
    domain_members = items.flat_map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value, item.attributes.dig('arcrole').value)
      [node.to_h] + find_domain_members(node)
    end
    domain_members
  end
end
