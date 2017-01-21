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
    locator: "uk-gaap-2009-09-01.xsd",
    tree: parsed_dts.tree,
  }
  JSON.pretty_generate(doc)
end

class TaxonomyParser

  def initialize
    @path = "dts_assets/uk-gaap/UK-GAAP-2009-09-01/uk-gaap-2009-09-01/"
  end

  def tree
    results = []
    pres_file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01-presentation.xml"
    pres_file = File.open(pres_file_path)
    pres_doc = Nokogiri::XML(pres_file)
    label_file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01-label.xml"
    label_file = File.open(label_file_path)
    label_doc = Nokogiri::XML(label_file)
    pres_doc.remove_namespaces!
    pres_doc.xpath('//presentationLink').first(5).each do |pl|
      h = {}
      pl.attributes.each do |k,v|
        h[k] = v
      end
      add_label_info(h, pres_doc)
      results << h
    end
    results
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
    # binding.pry
    h["concepts"] = root_locs.map { |rl| rl.attributes["label"].value }
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
