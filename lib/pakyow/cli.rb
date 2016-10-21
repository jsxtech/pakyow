require "thor"

module Pakyow
  # @api private
  class CLI < Thor
    map ["--version", "-v"] => :version

    desc "new [PROJECT_PATH]", "Create a new Pakyow project"
    long_desc <<-DESC
      The `pakyow new` command creates a new Pakyow project at the path you specify.

      $ pakyow new path/to/project
    DESC

    def new(destination)
      require "generators/pakyow/app/app_generator"
      Generators::AppGenerator.start(destination)
    end

    desc "console [ENVIRONMENT]", "Start an interactive Pakyow console"
    long_desc <<-DESC
      The `pakyow console` command starts a console session for the current Pakyow project,
      providing access to an application instance that you can interact with.

      If environment is unspecified, the default environment (#{Pakyow::DEFAULT_ENV}) will be used.
    DESC

    def console(env = Pakyow::DEFAULT_ENV)
      require "pakyow/commands/console"
      Commands::Console.new(env: env).run
    rescue LoadError => e
      raise Thor::Error, "Error: #{e.message}\n" \
        "You must run the `pakyow console` command in the root directory of a Pakyow project."
    end

    desc "server [ENVIRONMENT]", "Start a Pakyow application"
    long_desc <<-DESC
      The `pakyow server` command starts the server for the current Pakyow project.

      If environment is unspecified, the default environment (#{Pakyow::DEFAULT_ENV}) will be used.
    DESC
    option :port, type: :string, aliases: :p
    option :host, type: :string, aliases: :h
    option :server, type: :string, aliases: :s

    def server(env = Pakyow::DEFAULT_ENV)
      require "pakyow/commands/server"
      Commands::Server.new(
        env: env,
        port: options[:port],
        host: options[:host],
        server: options[:server]
      ).run
    rescue LoadError => e
      raise Thor::Error, "Error: #{e.message}\n" \
        "You must run the `pakyow server` command in the root directory of a Pakyow project."
    end

    desc "version", "Display the installed Pakyow version"
    def version
      puts "Pakyow v#{VERSION}"
    end
  end
end
