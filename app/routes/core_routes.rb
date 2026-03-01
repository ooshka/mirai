# frozen_string_literal: true

module Routes
  module Core
    def self.registered(app)
      app.get "/health" do
        {ok: true}.to_json
      end

      app.get "/config" do
        {notes_root: settings.notes_root}.to_json
      end
    end
  end
end
