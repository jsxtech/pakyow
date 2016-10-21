require "json"

module Pakyow
  module Middleware
    class JSONBody
      JSON_TYPE = "application/json".freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        if Rack::Request.new(env).media_type == JSON_TYPE && (body = env[Rack::RACK_INPUT].read).length != 0
          env.update(Rack::RACK_REQUEST_FORM_HASH => JSON.parse(body), Rack::RACK_REQUEST_FORM_INPUT => env[Rack::RACK_INPUT])
        end

        @app.call(env)
      end
    end
  end
end