RSpec.describe Pakyow do
  def config_defaults(config, env)
    Pakyow::Support::Configurable::ConfigGroup.new(
      config.name,
      config.options,
      config.parent,
      &config.defaults(env)
    )
  end

  describe "known events" do
    it "includes `configure`" do
      expect(Pakyow.known_events).to include(:configure)
    end

    it "includes `setup`" do
      expect(Pakyow.known_events).to include(:setup)
    end

    it "includes `fork`" do
      expect(Pakyow.known_events).to include(:fork)
    end
  end

  describe "configuration options" do
    after do
      Pakyow.reset
    end

    describe "env.default" do
      it "has a default value" do
        expect(Pakyow.config.env.default).to eq(:development)
      end
    end

    describe "server.default" do
      it "has a default value" do
        expect(Pakyow.config.server.default).to eq(:puma)
      end
    end

    describe "server.port" do
      it "has a default value" do
        expect(Pakyow.config.server.port).to eq(3000)
      end
    end

    describe "server.host" do
      it "has a default value" do
        expect(Pakyow.config.server.host).to eq("localhost")
      end
    end

    describe "console.object" do
      it "has a default value" do
        expect(Pakyow.config.console.object).to eq(IRB)
      end
    end

    describe "logger.enabled" do
      it "has a default value" do
        expect(Pakyow.config.logger.enabled).to eq(true)
      end

      context "in test" do
        it "defaults to false" do
          expect(config_defaults(Pakyow.config.logger, :test).enabled).to eq(false)
        end
      end

      context "in ludicrous" do
        it "defaults to false" do
          expect(config_defaults(Pakyow.config.logger, :ludicrous).enabled).to eq(false)
        end
      end
    end

    describe "logger.level" do
      it "has a default value" do
        expect(Pakyow.config.logger.level).to eq(:debug)
      end

      context "in production" do
        it "defaults to info" do
          expect(config_defaults(Pakyow.config.logger, :production).level).to eq(:info)
        end
      end
    end

    describe "logger.formatter" do
      it "has a default value" do
        expect(Pakyow.config.logger.formatter).to eq(Pakyow::Logger::DevFormatter)
      end

      context "in production" do
        it "defaults to logfmt" do
          expect(config_defaults(Pakyow.config.logger, :production).formatter).to eq(Pakyow::Logger::LogfmtFormatter)
        end
      end
    end

    describe "logger.destinations" do
      context "when logger is enabled" do
        before do
          Pakyow.config.logger.enabled = true
        end

        it "defaults to stdout" do
          expect(Pakyow.config.logger.destinations).to eq([$stdout])
        end
      end

      context "when logger is disabled" do
        before do
          Pakyow.config.logger.enabled = false
        end

        it "defaults to /dev/null" do
          expect(Pakyow.config.logger.destinations).to eq(["/dev/null"])
        end
      end
    end

    describe "normalizer.strict_path" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_path).to eq(true)
      end
    end

    describe "normalizer.strict_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_www).to eq(false)
      end
    end

    describe "normalizer.require_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.require_www).to eq(true)
      end
    end
  end

  describe ".mount" do
    let :app do
      Class.new
    end

    let :path do
      ""
    end

    context "called with an app and path" do
      before do
        Pakyow.mount app, at: path
      end

      it "registers the app" do
        expect(Pakyow.instance_variable_get(:@mounts)[path][:app]).to be(app)
      end

      context "and passed a block" do
        let :block do
          -> {}
        end

        before do
          Pakyow.mount app, at: path, &block
        end

        it "registers the block" do
          expect(Pakyow.instance_variable_get(:@mounts)[path][:block]).to be(block)
        end
      end
    end

    context "called without an app" do
      it "raises an error" do
        expect {
          Pakyow.mount at: path
        }.to raise_error(ArgumentError)
      end
    end

    context "called without a path" do
      it "raises an error" do
        expect {
          Pakyow.mount app
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".fork" do
    it "calls `forking`" do
      expect(Pakyow).to receive(:forking)
      Pakyow.fork {}
    end

    it "calls `forked`" do
      expect(Pakyow).to receive(:forked)
      Pakyow.fork {}
    end

    it "yields" do
      @called = false
      Pakyow.fork {
        @called = true
      }

      expect(@called).to be(true)
    end
  end

  describe ".forking" do
    it "calls before fork hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:before, :fork)
      Pakyow.forking
    end
  end

  describe ".forked" do
    it "calls after fork hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:after, :fork)
      Pakyow.forked
    end
  end

  describe ".call" do
    let :env do
      { foo: :bar }
    end

    it "calls the builder" do
      expect_any_instance_of(Rack::Builder).to receive(:call).with(env)
      Pakyow.call(env)
    end
  end

  describe ".reset" do
    before do
      allow(Pakyow).to receive(:handler).and_return(double.as_null_object)
      Pakyow.instance_variable_set(:@builder, double.as_null_object)
      Pakyow.config.server.default = :mock
      Pakyow.setup(env: :test).run
    end

    %i(@env @port @host @server @mounts @builder @logger).each do |var|
      it "resets #{var}" do
        expect(Pakyow.instance_variable_get(var)).to_not be_nil
        Pakyow.reset

        expect(Pakyow.instance_variable_get(var)).to be_nil
      end
    end

    it "resets the config" do
      config_double = double
      allow(Pakyow).to receive(:config).and_return(config_double)
      expect(config_double).to receive(:reset)
      Pakyow.reset
    end
  end

  describe ".setup" do
    context "called with an environment name" do
      let :name do
        :foo
      end

      before do
        Pakyow.setup(env: name)
      end

      it "uses the passed name" do
        expect(Pakyow.env).to be(name)
      end
    end

    context "called without an environment name" do
      before do
        Pakyow.setup
      end

      it "uses the default name" do
        expect(Pakyow.env).to be(Pakyow.config.env.default)
      end
    end

    it "calls hooks" do
      expect(Pakyow).to receive(:hook_around).with(:configure)
      expect(Pakyow).to receive(:hook_around).with(:setup)
      Pakyow.setup
    end

    it "configures for the environment" do
      env = :foo
      expect(Pakyow).to receive(:use_config).with(env)
      Pakyow.setup(env: env)
    end

    it "initializes the logger" do
      Pakyow.reset
      expect(Pakyow.logger).to be_nil
      Pakyow.setup

      expect(Pakyow.logger).to be_instance_of(Logger)
    end

    it "returns the environment" do
      expect(Pakyow.setup).to be(Pakyow)
    end
  end

  describe ".run" do
    before do
      allow(Pakyow).to receive(:handler).and_return(handler_double)
      Pakyow.instance_variable_set(:@builder, builder_double)
      Pakyow.run(port: port, host: host, server: server)
    end

    after do
      Pakyow.reset
    end

    let :handler_double do
      double.as_null_object
    end

    let :builder_double do
      double.as_null_object
    end

    let :port do
      4242
    end

    let :host do
      "local.dev"
    end

    let :server do
      :mock
    end

    context "called with a port" do
      it "uses the passed port" do
        expect(Pakyow.port).to be(port)
      end
    end

    context "called without a port" do
      let :port do
        nil
      end

      it "uses the default port" do
        expect(Pakyow.port).to be(Pakyow.config.server.port)
      end
    end

    context "called with a host" do
      it "uses the passed host" do
        expect(Pakyow.host).to be(host)
      end
    end

    context "called without a host" do
      let :host do
        nil
      end

      it "uses the default host" do
        expect(Pakyow.host).to be(Pakyow.config.server.host)
      end
    end

    context "called with a server" do
      it "uses the passed server" do
        expect(Pakyow.server).to be(server)
      end
    end

    context "called without a server" do
      let :server do
        nil
      end

      it "uses the default server" do
        expect(Pakyow.server).to be(Pakyow.config.server.default)
      end
    end

    it "looks up the handler for the server" do
      expect(Pakyow).to have_received(:handler).with(server)
    end

    it "runs the handler with the builder on the right host / port" do
      expect(handler_double).to have_received(:run).with(builder_double, Host: host, Port: port)
    end
  end
end
