module DimensionParser

  def parse_definition_linkbases
    Dir.glob("dts_assets/uk-gaap/**/*").grep(/definition.xml/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
    end
  end

  def find_primary_items(id)
    primary_items = @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:to='#{id}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/domain-member']")
        .map { |link| link.attributes["from"].value }
    end
    primary_items.map do |item|
      {
        primary_item: item,
        hypercubes: find_hypercubes(item)
      }
    end
  end

  def find_hypercubes(item)
    hypercubes = @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:from='#{item}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/all']")
        .map { |link| link.attributes["to"].value }
    end
    hypercubes.map do |cube|
      {
        hypercube: cube,
        dimensions: find_dimensions(cube)
      }
    end
  end

  def find_dimensions(hypercube)
    dimensions = @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:from='#{hypercube}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/hypercube-dimension']")
        .map { |link| link.attributes["to"].value }
    end
    dimensions.map do |dimension|
      {
        dimension: dimension,
        domains: find_domains(dimension)
      }
    end
  end

  def find_domains(dimension)
    arcroles = [
      "http://xbrl.org/int/dim/arcrole/dimension-default",
      "http://xbrl.org/int/dim/arcrole/dimension-domain"
    ]
    domains = @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:from='#{dimension}' and contains('#{arcroles}', @xlink:arcrole)]")
        .map { |link| { to: link.attributes["to"].value, arcrole: link.attributes["arcrole"].value } }
    end
    domains.map do |domain|
      {
        domain: domain,
        members: find_domain_members(domain[:to])
      }
    end
  end

  def find_domain_members(domain)
    @definitions.flat_map do |parsed_file|
      parsed_file
        .xpath("//xmlns:definitionArc[@xlink:from='#{domain}' and @xlink:arcrole='http://xbrl.org/int/dim/arcrole/domain-member']")
        .map { |link| link.attributes["to"].value }
    end
  end

end
