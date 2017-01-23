require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'

configure { set :server, :puma }

get '/' do
  content_type :json
  parsed_dts = TaxonomyParser.new
  doc = {
    network: "Presentation",
    lang: "en",
    tree: parsed_dts.tree,
  }
  JSON.pretty_generate(doc)
end

class TaxonomyParser

  def initialize
    @path = "dts_assets/uk-gaap/UK-GAAP-2009-09-01/uk-gaap-2009-09-01/"
    @schema_filename = "uk-gaap-2009-09-01.xsd"
    @label_doc = parse_label_doc
    @reference_doc = parse_reference_doc
  end

  def parse_label_doc
    label_file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01-label.xml"
    label_file = File.open(label_file_path)
    Nokogiri::XML(label_file)
  end

  def parse_reference_doc
    file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01-reference.xml"
    file = File.open(file_path)
    Nokogiri::XML(file)
  end

  def tree
    results = []
    pres_file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01-presentation.xml"
    pres_file = File.open(pres_file_path)
    pres_doc = Nokogiri::XML(pres_file)
    pres_doc.remove_namespaces!
    pres_doc.xpath('//presentationLink').first(5).each do |pl|
      h = {}
      pl.attributes.each do |k,v|
        h[k] = v
      end
      add_label_info(h, pres_doc)
      results << h
    end
    results.uniq! { |r| r["role"].value }
  end

  def add_label_info(h, pres_doc)
    roleURI = h['role'].value
    link = pres_doc.xpath("//*[@roleURI='#{roleURI}']")
    anchor = link.first.attributes["href"].value
    id = anchor.split('#').last
    app_info = schema_doc.xpath("//*[@id='#{id}']").first
    app_info.elements.each do |el|
      h[el.name] = el.text
    end
    add_concepts_to_tree(h, pres_doc)
  end

  def add_concepts_to_tree(h, pres_doc)
    role = h["role"]
    presentation_link = pres_doc.xpath("//*[@role='#{role}']")
    locs = presentation_link.first.xpath('.//loc')
    presentation_arcs = presentation_link.first.xpath('.//presentationArc')
    presentation_arc_to_links = presentation_arcs.map { |pa| pa.attributes["to"].value }
    root_locs = locs.reject do |loc|
      to = loc.attributes["label"].value
      presentation_arc_to_links.include? to
    end
    h["concepts"] = root_locs.map do |root_loc|
      {
        labels: labels_for_concept(root_loc),
        references: references_for_concept(root_loc),
        properties: properties_for_concept(root_loc)
      }
    end
  end

  def labels_for_concept(concept)
    # binding.pry
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
    # binding.pry
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
    {}
  end

  def schema_doc
    file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01.xsd"
    file = File.open(file_path)
    Nokogiri::XML(file)
  end

  # def app_info
  #   results = []
  #   links = schema_doc.xpath('//link:roleType')
  #   # binding.pry
  #   links.each do |link|
  #     id = link.attributes['id'].value
  #     definition = link.elements.find { |el| el.name == "definition" }
  #     used_on = link.elements.find { |el| el.name == "usedOn" }.text
  #     label = definition.children.first.text if definition
  #     position = label.split(' ').first.to_i
  #     results << {
  #       id: id,
  #       position: position,
  #       definition: label,
  #       used_on: used_on
  #     }
  #   end
  #   results
  # end

end
