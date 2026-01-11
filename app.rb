# frozen_string_literal: true

require "sinatra/base"
require "json"

class App < Sinatra::Base
  set :bind, "0.0.0.0"
  set :port, (ENV["PORT"] || "4567").to_i
  
  configure do
    set :notes_root, ENV.fetch("NOTES_ROOT", "/notes")
  end

  before do
    content_type :json
  end

  get "/health" do
    { ok: true }.to_json
  end

  get "/config" do
    { notes_root: settings.notes_root }.to_json
  end
end
