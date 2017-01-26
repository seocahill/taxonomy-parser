require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'

configure { set :server, :puma }

get '/' do
  content_type :json
  TaxonomyParser.new.dts_as_json
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

    Dir.glob("dts_assets/uk-gaap/**/*.xsd").grep_v(/(full|main|minimum)/) do |file|
      parsed_file = Nokogiri::XML(File.open(file))
      parsed_role_types = parsed_file.xpath("//link:roleType")
      parsed_role_types.each do |role_type|
        role_URI = role_type.attributes["roleURI"].value
        role_types[role_URI] = role_type.children.each_with_object({}) do |child, obj|
          obj[child.name] = child.text
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
          locators[loc.attributes['label'].value] = {
            href: href,
            label: label
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
            to_loc[:parent] = arc.attributes["from"]&.value
            to_loc[:order] = arc.attributes["order"]&.value
          end
        end
        root_nodes = locators.reject do |k,v|
          v.has_key?(:parent)
        end

        root_nodes.each do |k,v|
          v[:children] = children_for_node(locators, k)
        end

        linkbases[role] = {
          label: role_types[role]["definition"],
          nodes: root_nodes
        }
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
