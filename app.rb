require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'

configure { set :server, :puma }

get '/' do
  content_type :json
  JSON.pretty_generate(TaxonomyParser.new.dts_as_json)
end

class TaxonomyParser

  def initialize
    @path = "dts_assets/uk-gaap/UK-GAAP-2009-09-01/uk-gaap-2009-09-01/"
    @schema_filename = "uk-gaap-2009-09-01.xsd"
    @schema_doc = parse_doc("gaap/core/2009-09-01/uk-gaap-2009-09-01.xsd")
    @label_doc = parse_doc("gaap/core/2009-09-01/uk-gaap-2009-09-01-label.xml")
    @reference_doc = parse_doc("gaap/core/2009-09-01/uk-gaap-2009-09-01-reference.xml")
    @definition_doc = parse_doc("gaap/core/2009-09-01/uk-gaap-2009-09-01-definition.xml")
    @pres_doc = parse_doc("gaap/core/2009-09-01/uk-gaap-2009-09-01-presentation.xml")
    @network = "Presentation"
    @language = "en"
  end

  def dts_as_json
    {
      network: @network,
      lang: @language,
      presentation_tree: render_presentation_tree_as_json,
      definition_tree: render_definition_tree_as_json
    }
  end

  def render_definition_tree_as_json
=begin
  what I need to do here is render all the definition nodes as with the presentation linkbase
  Then filter by the chosen network. In effect the presentation linkbase has a single network
  'parent-child' but it could have more. Hence I should be able to abstract and share the logic.
=end
    @definition_doc.xpath('//xmlns:definitionLink')
    .to_a
    .uniq { |r| r.attributes["role"].value }
    .map do |pl|
      h = {}
      pl.attributes.each do |k,v|
        h[k] = v.value
      end
      add_dl_label_info(h)
    end
  end

  def add_dl_label_info(h)
    roleURI = h['role']
    link = @definition_doc.xpath("//*[@roleURI='#{roleURI}']")
    anchor = link.first.attributes["href"].value
    id = anchor.split('#').last
    app_info = @schema_doc.xpath("//*[@id='#{id}']").first
    if app_info
      app_info.elements.each do |el|
        h[el.name] = el.text
      end
      # add_concepts_to_tree(h)
    end
    h
  end

  def render_presentation_tree_as_json
    @pres_doc.xpath('//xmlns:presentationLink')
    .to_a
    .uniq { |r| r.attributes["role"].value }
    .map do |pl|
      h = {}
      pl.attributes.each do |k,v|
        h[k] = v.value
      end
      add_label_info(h)
    end
  end

  def add_label_info(h)
    roleURI = h['role']
    link = @pres_doc.xpath("//*[@roleURI='#{roleURI}']")
    anchor = link.first.attributes["href"].value
    id = anchor.split('#').last
    app_info = @schema_doc.xpath("//*[@id='#{id}']").first
    if app_info
      app_info.elements.each do |el|
        h[el.name] = el.text
      end
      add_concepts_to_tree(h)
    end
    h
  end

  def add_concepts_to_tree(h)
    role = h["role"]
    presentation_link = @pres_doc.xpath("//*[@xlink:role='#{role}']")
    locs = presentation_link.first.xpath('.//xmlns:loc')
    presentation_arcs = presentation_link.first.xpath('.//xmlns:presentationArc')
    presentation_arc_to_links = presentation_arcs.map { |pa| pa.attributes["to"].value }
    root_locs = locs.reject do |loc|
      to = loc.attributes["label"].value
      presentation_arc_to_links.include? to
    end
    h["children"] = root_locs.map do |root_loc|
      add_children_to_node(root_loc)
    end
  end

  def add_children_to_node(node)
    {
      labels: labels_for_concept(node),
      references: references_for_concept(node),
      properties: properties_for_concept(node),
      children: []
    }
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
    loc = @reference_doc.xpath("//*[@xlink:href='#{link}']").first.attributes["label"].value
    from = @reference_doc.xpath("//*[@xlink:from='#{loc}']").first.attributes['to'].value
    references = @reference_doc.xpath("//*[@xlink:label='#{from}']")
    references.map do |ref|
      {
        type: ref.attributes["type"].value,
        reference: ref.text
      }
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

end
