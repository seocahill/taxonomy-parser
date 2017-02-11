module DimensionParser

  # Items inheriting basic dimensions

  Node = Struct.new(:id, :element_id, :parent_id, :order)

  def parse_definition_linkbases
    Dir.glob("dts_assets/uk-gaap/**/*").grep(/definition.xml/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
    end
  end

  def new_node(element, parent = nil, order = "0")
    Node.new(SecureRandom.uuid, element, parent, order)
  end

  def dimension_node_tree(concept_id)
    nodes = []
    find_primary_items(concept_id, nodes)
    nodes
  end

  def find_primary_items(parent_id, nodes)
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:to='#{parent_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/domain-member']")
    end
    items.map do |item|
      node = new_node(item.attributes["from"].value, nil, item.attributes.dig("order")&.value)
      nodes << node.to_h
      find_hypercubes(node, nodes)
    end
  end

  def find_hypercubes(parent, nodes)
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/all']")
    end
    items.map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value)
      nodes << node.to_h
      find_dimensions(node, nodes)
    end
  end

  def find_dimensions(parent, nodes)
    items = @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/hypercube-dimension']")
    end
    items.map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value)
      nodes << node.to_h
      find_domains(node, nodes)
    end
  end

  def find_domains(parent, nodes)
    arcroles = [
      "http://xbrl.org/int/dim/arcrole/dimension-default",
      "http://xbrl.org/int/dim/arcrole/dimension-domain"
    ]
   items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and contains('#{arcroles}', @xlink:arcrole)]")
    end
    items.map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value)
      nodes << node.to_h
      find_domain_members(node, nodes)
    end
  end

  def find_domain_members(parent, nodes)
    items = @definitions.flat_map do |parsed_file|
      parsed_file.xpath("//xmlns:definitionArc[@xlink:from='#{parent.element_id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/domain-member']")
    end
    items.map do |item|
      node = new_node(item.attributes["to"].value, parent.id, item.attributes.dig("order")&.value)
      nodes << node.to_h
    end
  end
end
