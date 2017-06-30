module SchemaParser
  def parse_dts_schemas
    entries = {}
    role_types = {}
    Dir.glob(File.join(__dir__, "/../../dts_assets/uk-gaap/**/*.xsd")).grep_v(/(full|main|minimum)/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_nodes = parsed_file.search("link|roleType", "element")
      current_tuple_id = nil
      parsed_nodes.each do |node|
        if node.name == "roleType"
          role_URI = node.attributes["roleURI"].value
          role_types[role_URI] = node.children.each_with_object({}) do |child, obj|
            obj[child.name] = child.text
          end
        elsif node.name == "element" && node.attributes.has_key?("ref")
          tuple = entries[current_tuple_id]
          members = tuple["tuple_members"] ||= []
          members << hashify_xml(node)
        elsif node.name == "element"
          entries[node.attributes["id"].value] = hashify_xml(node)
          current_tuple_id = node.attributes["id"].value if node.attributes["substitutionGroup"].value == "xbrli:tuple"
        end
      end
    end
    [entries, role_types]
  end

  def parse_elements
    bucket = @store[:elements] = {}
    @concepts.each do |id, v|
      model = Element.new(id, @current_dts.id, v["name"], v["type"], v["substitutionGroup"], v["periodType"], v["abstract"], v["nillable"])
      bucket[model.id] = model
    end
  end

  def parse_roles
    bucket = @store[:role_types] = {}
    @role_types.each do |uri, role|
      id = (bucket.keys.last || 0) + 1
      model = RoleType.new(id, @current_dts.id, role["definition"], uri, role["usedOn"])
      bucket[model.id] = model 
    end
    @current_dts.role_types = @store[:role_types].values
      .select { |item| item.network == "link:presentationLink" }
      .sort_by { |item| item.order }
  end
end
