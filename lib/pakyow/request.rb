require "rack/request"

require "pakyow/support/indifferentize"

module Pakyow
  # Pakyow's Request object.
  #
  # @api public
  class Request < Rack::Request
    using Pakyow::Support::Indifferentize

    # Contains the error object when request is in a failed state.
    #
    # @api public
    attr_accessor :error

    def initialize(*)
      super
      @env["CONTENT_TYPE"] = "text/html"
    end

    # Returns the request method (e.g. `:get`).
    #
    # @api public
    def method
      request_method.downcase.to_sym
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
    # @api public
    def format
      type = Rack::Mime::MIME_TYPES.select { |key, value|
        value == @env["CONTENT_TYPE"]
      }

      return if type.empty?
      extension = type.keys.first
      # works around a dumb thing in Rack::Mime
      return :html if extension == ".htm"
      extension[1..-1].to_sym
    end

    # Returns an indifferentized params hash.
    #
    # @api public
    def params
      # TODO: any reason not to just use rack.input?
      # @params.merge!(env['pakyow.data']) if env['pakyow.data'].is_a?(Hash)
      @params = super.indifferentize
    end

    # Returns an indifferentized cookie hash.
    #
    # @api public
    def cookies
      @cookies ||= super.indifferentize
    end
  end
end
