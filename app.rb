require 'bundler'
require 'logger'
require 'json'

ENV['RACK_ENV'] ||= 'development'
Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative 'routes'

module TaxonomyParser
  class Base < Sinatra::Base
    set :server, :puma
    mime_type :api_json, 'application/vnd.api+json'

    def initialize
      super()
      load_files
    end

    def load_files
      files = Dir.glob(File.join(__dir__, "/lib/**/*.rb"))
      files.grep(/base_/).each { |file| require file }
      files.grep_v(/base_/).each { |file| require file }
    end

    register Routes
  end
end