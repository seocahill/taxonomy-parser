require 'bundler'
require 'logger'
require 'json'

ENV['RACK_ENV'] ||= 'development'
Bundler.require :default, ENV['RACK_ENV'].to_sym
require_relative 'lib/routes'

module TaxonomyParser
  class Base < Sinatra::Base
    set :server, :puma
    mime_type :api_json, 'application/vnd.api+json'

    def initialize
      super()
      Dir.glob(File.join(__dir__, "/lib/**/*.rb")).each {|file| require file }
    end

    register Routes
  end
end