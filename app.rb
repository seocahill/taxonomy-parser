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
    appInfo: parsed_dts.app_info
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
    pres_doc.xpath('//presentationLink').first(1).each do |pl|
      results << pl.attributes['title']&.value || 'no title given'
    end
    results
  end

  def app_info
    results = []
    file_path = @path + "gaap/core/2009-09-01/uk-gaap-2009-09-01.xsd"
    file = File.open(file_path)
    doc = Nokogiri::XML(file)
    links = doc.xpath('//link:roleType')
    # binding.pry
    links.each do |link|
      id = link.attributes['id'].value
      definition = link.elements.find { |el| el.name == "definition" }
      used_on = link.elements.find { |el| el.name == "usedOn" }.text
      label = definition.children.first.text if definition
      position = label.split(' ').first.to_i
      results << {
        id: id,
        position: position,
        definition: label,
        used_on: used_on
      }
    end
    results
  end

end
