# frozen_string_literal: true

ENV["RACK_ENV"] = "test"

require "rack/test"
require "json"
require_relative "../app"

module RSpecMixin
  include Rack::Test::Methods
  def app = App
end

RSpec.configure do |config|
  config.include RSpecMixin
end
