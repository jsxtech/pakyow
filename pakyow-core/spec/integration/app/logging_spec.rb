require 'support/helper'

RSpec.describe 'Logging for the app' do
  before do
    # @original_builder = Pakyow::App.builder
    # Pakyow::App.instance_variable_set(:@builder, double(Rack::Builder).as_null_object)

    Pakyow.setup(env: :test)
  end

  after do
    # Pakyow::App.instance_variable_set(:@builder, @original_builder)
  end

  # TODO: move to test pakyow/core/hooks (integration test)
  # describe 'using the middleware' do
  #   context 'when logger is enabled' do
  #     before do
  #       Pakyow::App.config.logger.enabled = true
  #     end

  #     it 'uses the logger middleware' do
  #       expect(Pakyow::App.builder).to receive(:use).with(Pakyow::Middleware::Logger)
  #     end
  #   end
  # end

  describe 'the after error hook' do
    let :hook do
      Pakyow::CallContext.instance_variable_get(:@hook_hash)[:after][:error][0][1]
    end

    let :logger do
      double.as_null_object
    end

    let :req do
      double
    end

    let :err do
      ArgumentError.new
    end

    xit 'is registered' do
      expect(hook.source_location[0]).to include("pakyow-core/lib/pakyow/core/middleware/logger.rb")
    end

    it 'calls logger.houston with req.error' do
      expect(logger).to receive(:houston).with(err)
      expect(req).to receive(:error).and_return(err)
      instance_exec(&hook)
    end
  end
end
