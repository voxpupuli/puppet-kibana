require 'spec_helper'

describe Puppet::Type.type(:kibana_plugin) do
  let(:resource_name) { 'x-pack' }

  describe 'input validation' do
    it 'should default to being installed' do
      plugin = described_class.new(:name => resource_name )
      expect(plugin.should(:ensure)).to eq(:present)
    end

    describe 'when validating attributes' do
      it 'should have a url parameter' do
        expect(described_class.attrtype(:url)).to eq(:param)
      end

      it 'should have an ensure property' do
        expect(described_class.attrtype(:ensure)).to eq(:property)
      end

      it 'should have a version property' do
        expect(described_class.attrtype(:version)).to eq(:property)
      end
    end
  end
end
