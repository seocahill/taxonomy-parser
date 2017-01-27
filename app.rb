require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'

configure { set :server, :puma }

get '/' do
  content_type :json
  TaxonomyParser.new.tree_json
end

get '/tree' do
  content_type :json
  TaxonomyParser.new.tree_json
end

class TaxonomyParser

# Todo
# create full tree from all pres and def files that is filterable by arcrole
# apply labels, references and properties
# locators labels are unique  scoped to the parent extended link role

  # def initialize

  # end

  def tree_json
    linkbases = {}
    role_types = {}
    label_locs = {}
    label_links = {}
    label_labels = {}
    properties = {}
    references = {}
    reference_locs = {}
    reference_links = {}
    network_locations = {}

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
          tuple = properties[current_tuple_id]
          members = tuple["tuple_members"] ||= []
          members << hashify_xml(node)
        elsif node.name == "element"
          properties[node.attributes["id"].value] = hashify_xml(node)
          current_tuple_id = node.attributes["id"].value if node.attributes["substitutionGroup"].value == "xbrli:tuple"
        end
      end
    end

    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/label/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'labelArc', 'label').each do |item|
        case item.name
        when "loc"
          label_locs[item.attributes["label"].value] = hashify_xml(item)
        when "labelArc"
          label_links[item.attributes["from"].value] = hashify_xml(item)
        when "label"
          l = label_labels[item.attributes["label"].value] ||= {}
          l[item.attributes["role"].value] = item.text
        end
      end
    end

    Dir.glob("dts_assets/uk-gaap/**/*.xml").grep(/reference/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_file.search('loc', 'referenceArc', 'reference').each do |item|
        case item.name
        when "loc"
          reference_locs[item.attributes["label"].value] = hashify_xml(item)
        when "referenceArc"
          reference_links[item.attributes["from"].value] = hashify_xml(item)
        when "reference"
          ref = references[item.attributes["label"].value] ||= {}
          attrs = ref[item.attributes["role"].value] = {}
          item.elements.each { |element| attrs[element.name] = element.text }
        end
      end
    end

    Dir.glob("dts_assets/uk-gaap/**/direp/**/*").grep(/(definition.xml|presentation.xml)/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_links = parsed_file.xpath("//*[self::xmlns:definitionLink or self::xmlns:presentationLink]")
      links = {}
      parsed_links.each do |link|
        role = link.attributes["role"].value
        locators = links[role] ||= {}
        link.xpath("./xmlns:loc").each do |loc|
          href = loc.attributes['href'].value
          loc_label = label_locs[href.split("#").last]["label"]
          link_to = label_links[loc_label]["to"]
          label = label_labels[link_to]["http://www.xbrl.org/2003/role/label"]
          reference = "This concept does not have any references."
          loc_ref = reference_locs.dig(href.split("#").last, "label")
          if loc_ref
            ref_link_to = reference_links[loc_ref]["to"]
            reference = references[ref_link_to]
          end
          node_properties = properties[href.split("#").last]
          locators[loc.attributes['label'].value] = {
            href: href,
            label: label,
            reference: reference,
            properties: node_properties
          }
        end
      end
      parsed_links.each do |link|
        role = link.attributes["role"].value
        locators = links[role]
        link.xpath("./*[self::xmlns:definitionArc or self::xmlns:presentationArc]").each do |arc|
          from_loc = locators[arc.attributes["from"].value]
          from_loc[:arcrole] = arc.attributes["arcrole"]&.value if from_loc
          to_loc = locators[arc.attributes["to"].value]
          if to_loc
            network_locations[arc.attributes["to"].value] ||= [] << Hash[arc.attributes["arcrole"]&.value, arc.attributes["from"]&.value]
            to_loc[:parent] = arc.attributes["from"]&.value
            to_loc[:order] = arc.attributes["order"]&.value
          end
        end
        root_nodes = locators.reject do |k,v|
          v.has_key?(:parent)
        end

        root_nodes.each do |k,v|
          v[:tree_locations] ||= [] << Hash[k, "root_node"]
          v[:children] = children_for_node(locators, k)
        end

        linkbases[role] = {
          label: role_types[role]["definition"],
          nodes: root_nodes
        }
      end
    end
    linkbases.each do |k,v|
      v[:nodes].each do |a,b|
        add_tree_locations_to_nodes(a, b, network_locations)
      end
    end
    linkbases.to_json
  end

  def children_for_node(locators, k)
    children = locators.select { |a,b| b[:parent] == k }
    children.each do |a,b|
      b[:children] = children_for_node(locators, a)
    end
  end

  def labels_for_concept(concept)
    link = @schema_filename + "#" + concept.attributes["label"].value
    loc = @label_doc.xpath("//*[@xlink:href='#{link}']").first.attributes["label"].value
    from = @label_doc.xpath("//*[@xlink:from='#{loc}']").first.attributes['to'].value
    labels = @label_doc.xpath("//*[@xlink:label='#{from}']")
    labels.map do |label|
      {
        type: label.attributes["role"].value,
        language: label.attributes["lang"],
        label: label.text
      }
    end
  end

  def references_for_concept(concept)
    link = @schema_filename + "#" + concept.attributes["label"].value
    locs = @reference_doc.xpath("//*[@xlink:href='#{link}']")
    if locs.any?
      loc = locs.first.attributes["label"].value
      from = @reference_doc.xpath("//*[@xlink:from='#{loc}']").first.attributes['to'].value
      references = @reference_doc.xpath("//*[@xlink:label='#{from}']")
      references.map do |ref|
        {
          type: ref.attributes["type"].value,
          reference: ref.text
        }
      end
    end
  end

  def properties_for_concept(concept)
    props = {}
    link = concept.attributes["label"].value
    concept_element = @schema_doc.xpath("//*[@id='#{link}']").first
    concept_element.attributes.each do |k,v|
      props[k] = v
    end
    props
  end

  def add_tree_locations_to_nodes(key, value, network_locations)
    value[:tree_locations] = network_locations[key] || Hash[value[:arcrole], "root_node"]
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
