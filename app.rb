require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'
require 'set'

configure { set :server, :puma }

get '/' do
  content_type :json
  TaxonomyParser.new.tree_json
end

class TaxonomyParser # lang=en, dts=uk-gaap

  def initialize
    @concepts, @role_types = parse_dts_schemas
    @label_items = parse_label_linkbases
    @reference_items = parse_reference_linkbases
    @network_locations = {}
  end

  def parse_dts_schemas
    entries = {}
    role_types = {}
    Dir.glob("dts_assets/uk-gaap/**/*.xsd").grep_v(/(full|main|minimum)/) do |file|
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
    [entires, role_types]
  end

  def parse_label_linkbases
    entries = { locs: {}, links: {}, resources: {} }
    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/label/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'labelArc', 'label').each do |item|
        case item.name
        when "loc"
          entries[locs][item.attributes["label"].value] = hashify_xml(item)
        when "labelArc"
          entries[links][item.attributes["from"].value] = hashify_xml(item)
        when "label"
          resource = entries[resources][item.attributes["label"].value] ||= {}
          resource[item.attributes["role"].value] = item.text
        end
      end
    end
    entries
  end

  def parse_reference_linkbases
    entries = { locs: {}, links: {}, resources: {} }
    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/reference/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'referenceArc', 'reference').each do |item|
        case item.name
        when "loc"
          entries[locs][item.attributes["label"].value] = hashify_xml(item)
        when "referenceArc"
          entries[links][item.attributes["from"].value] = hashify_xml(item)
        when "reference"
          resource = entries[resources][item.attributes["label"].value] ||= {}
          attrs = resource[item.attributes["role"].value] = {}
          item.elements.each { |element| attrs[element.name] = element.text }
        end
      end
    end
    entries
  end

  def parse_presentation_linkbases
    Dir.glob("dts_assets/uk-gaap/**/*").grep(/(definition.xml|presentation.xml)/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_links = parsed_file.xpath("//*[self::xmlns:definitionLink or self::xmlns:presentationLink]")
      links = {}
      nodes = parse_nodes(parsed_links)
      construct_graph(parsed_links, nodes)
    end
    @concepts.each do |k,v|
      v[:nodes].each do |a,b|
        add_tree_locations_to_nodes(a, b, network_locations)
      end
    end
    @concepts.to_json
  end

  def parse_nodes(links)
    entries = {}
    links.each do |link|
      role = link.attributes["role"].value
      locators = entries[role] ||= {}
      link.xpath("./xmlns:loc").each do |loc|
        href = loc.attributes['href'].value
        loc_label = label_locs[href.split("#").last]["label"]
        link_to = @label_items[:links][loc_label]["to"]
        label = @label_items[:resources][link_to]["http://www.xbrl.org/2003/role/label"]
        reference = "This concept does not have any references."
        loc_ref = @reference_items[:locs].dig(href.split("#").last, "label")
        if loc_ref
          ref_link_to = @reference_items[:links][loc_ref]["to"]
          reference = @reference_items[:resources][ref_link_to]
        end
        node_properties = @concepts[href.split("#").last]
        locators[loc.attributes['label'].value] = {
          href: href,
          label: label,
          reference: reference,
          properties: node_properties
        }
      end
    end
    entries
  end

  def build_graph(parsed_links, links)
    parsed_links.each do |link|
      role = link.attributes["role"].value
      locators = links[role]
      link.xpath("./*[self::xmlns:definitionArc or self::xmlns:presentationArc]").each do |arc|
        from_loc = locators[arc.attributes["from"].value]
        from_loc[:arcrole] = arc.attributes["arcrole"]&.value if from_loc
        to_loc = locators[arc.attributes["to"].value]
        if to_loc
          tree_locs = @network_locations[arc.attributes["to"].value] ||= Set.new
          tree_locs << Hash[arc.attributes["arcrole"]&.value, arc.attributes["from"]&.value]
          to_loc[:parent] = arc.attributes["from"]&.value
          to_loc[:order] = arc.attributes["order"]&.value
        end
      end
      root_nodes = locators.reject do |k,v|
        v.has_key?(:parent)
      end

      root_nodes.each do |k,v|
        @network_locations[k] ||= Set.new
        @network_locations[k] << Hash[role, "root_node"]
        v[:children] = children_for_node(locators, k)
      end

      @concepts[role] = {
        label: @role_types[role]["definition"],
        nodes: root_nodes
      }
    end
  end

  def children_for_node(locators, k)
    children = locators.select { |a,b| b[:parent] == k }
    children.each do |a,b|
      b[:children] = children_for_node(locators, a)
    end
  end

  def add_tree_locations_to_nodes(key, value, network_locations)
    value[:tree_locations] = network_locations[key]&.to_a #|| Hash[value[:arcrole], "root_node"]
    value[:children].each do |k,v|
      add_tree_locations_to_nodes(k, v, network_locations)
    end
  end

private

  def parse_doc(doc_path)
    file_path = @path + doc_path
    file = File.open(file_path)
    Nokogiri::XML(file)
  end

  def hashify_xml(xml)
    xml.each_with_object({}) { |(k,v), hsh| hsh[k] = v }
  end
end
