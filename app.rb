require 'sinatra'
require 'nokogiri'
require 'json'
require 'pry'

configure { set :server, :puma }

get '/' do
  content_type :json
  doc = {
    network: "Presentation",
    lang: "en",
    locator: "uk-gaap-2009-09-01.xsd",
    appInfo: TaxonomyParser.new.app_info
  }
  JSON.pretty_generate(doc)
end

class TaxonomyParser

  def app_info
    results = []
    file_path = "dts_assets/uk-gaap/UK-GAAP-2009-09-01/uk-gaap-2009-09-01/gaap/core/2009-09-01/uk-gaap-2009-09-01.xsd"
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
