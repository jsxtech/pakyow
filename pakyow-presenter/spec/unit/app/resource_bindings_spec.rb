require 'spec_helper'
require_relative '../../../../pakyow-core/spec/support/helpers/req_res_helpers.rb'

describe Pakyow::App, '#resource' do
  include ReqResHelpers

  let(:app) { Pakyow::App.new }

  context 'called with a resource name, path, and block' do
    before do
      app.resource :test, "tests" do
        list do
        end
      end

      app.presenter.load
    end

    it 'creates a binding set for the resource name' do
      scope = Pakyow::Presenter::Binder.instance.sets[:main].scopes[:test]
      expect(scope).not_to be_nil
    end

    describe 'the binding set block' do
      let(:binding_set_block) { app.bindings[:main] }

      it 'exists' do
        expect(binding_set_block).to be_kind_of Proc 
      end

      context 'when evaluated' do
        let(:set) { Pakyow::Presenter::BinderSet.new(&binding_set_block) }

        it 'creates restful bindings with with scope for resource name' do
          expect(set.has_prop?(:test, :_root, {})).to be true
        end
      end
    end
  end

  context 'called without a block' do
    before do
      Pakyow::App.routes :test do
        restful :test, "tests" do
          list do
          end
        end
      end
    end

    it 'presenter does not override core method' do
      expect(app.resource(:test)).to eq Pakyow::App.routes[:test]
    end
  end

  context 'called without a path' do
    it 'presenter does not override core method' do
      no_path_passed = Proc.new { app.resource(:test) {} }
      nil_path_passed = Proc.new { app.resource(:test, nil) {} }
      expect(no_path_passed).to raise_error ArgumentError
      expect(nil_path_passed).to raise_error ArgumentError
    end
  end

  context 'called without a resource name' do
    it 'presenter does not override core method' do
      no_name_passed = Proc.new { app.resource() {} }
      nil_name_passed = Proc.new { app.resource(nil, "tests") {} }
      expect(no_name_passed).to raise_error ArgumentError
      expect(nil_name_passed).to raise_error ArgumentError
    end
  end
end
