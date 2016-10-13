require 'pakyow/core/call_context'

module Pakyow
  module Middleware
    # Rack compatible middleware that normalize the path if contains '//'
    # or has a trailing '/', it replace '//' with '/', remove trailing `/`
    # and issue a 301 redirect to the normalized path.
    #
    # @api public
    class ReqPathNormalizer
      TAIL_SLASH_REPLACE_REGEX = /(\/)+$/
      TAIL_SLASH_REGEX = /(.)+(\/)+$/

      def initialize(app)
        @app = app
      end

      def call(env)
        path = env['PATH_INFO']

        if double_slash?(path) || tail_slash?(path)
          catch :halt do
            CallContext.new(env).redirect(normalize_path(path), 301)
          end
        else
          @app.call(env)
        end
      end

      def normalize_path(path)
        path
          .gsub('//', '/')
          .gsub(TAIL_SLASH_REPLACE_REGEX, '')
      end

      def double_slash?(path)
        path.include?('//')
      end

      def tail_slash?(path)
        (TAIL_SLASH_REGEX =~ path).nil? ? false : true
      end
    end
  end
end
