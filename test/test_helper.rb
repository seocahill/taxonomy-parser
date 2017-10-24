ENV['RACK_ENV'] = 'test'
require 'simplecov'
SimpleCov.start do 
  add_filter "/test/"
end
require_relative '../app'
require 'minitest/autorun'
require 'rack/test'
# require 'pry-rescue/minitest'

module TaxonomyParser
  module TestHelper

    def test_obj
      self.class.class_variable_get(:@@test_obj)
    end

    def log_response
      File.open("logs/last_response.json","w") do |f|
        f.write(last_response.body)
      end
    end

    def json_data(type="data")
      JSON.parse(last_response.body)[type]
    end

    def json_includes(type="data", attr, required)
      return false unless json_data(type)
      actual = json_data(type).map { |model| model["attributes"][attr] }
      (required - actual).empty?
    end

    def lookup_nodes(element_id)
      test_obj.store[:elements][element_id].presentation_nodes
    end

    # are these used?
    def find_children(element_id, nodes)
      parent = find_node(element_id, nodes)
      nodes.select { |node| node.parent == parent }
    end

    def find_node(element_id, nodes)
      nodes.find { |node| node.element_id == element_id }
    end
  end
end