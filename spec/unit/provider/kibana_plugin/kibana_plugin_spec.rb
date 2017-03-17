require 'spec_helper'

def plug_path(path)
  File.absolute_path(
    File.join(
      %w(/ usr share kibana plugins) + path
    )
  )
end

describe Puppet::Type.type(:kibana_plugin).provider(:kibana_plugin) do
  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end

    context 'without plugins' do
      before do
        allow(Dir).to receive(:[]).and_return %w(. ..)
      end

      it 'should return no resources' do
        expect(described_class.instances.size).to eq(0)
      end
    end

    context 'with one plugin' do
      before do
        allow(Dir).to receive(:[]).and_return [plug_path(['x-pack'])]
        allow(File).to receive(:read)
          .with(plug_path(%w(x-pack package.json)))
          .and_return '{"name":"x-pack","version":"5.2.1"}'
        allow(File).to receive(:exist?)
          .with(plug_path(%w(x-pack package.json)))
          .and_return true
      end

      subject { described_class.instances.first }

      it { expect(subject.exists?).to be_truthy }
      it { expect(subject.name).to eq('x-pack') }
      it { expect(subject.version).to eq('5.2.1') }
    end

    context 'with multiple plugins' do
      before do
        allow(Dir).to receive(:[])
          .and_return %w(x-pack logtrail).map { |p| plug_path [p] }
        %w(x-pack logtrail).each do |plugin|
          allow(File).to receive(:read)
            .with(plug_path([plugin, 'package.json']))
            .and_return format('{"name":"%s","version":"5.2.0"}', plugin)
          allow(File).to receive(:exist?)
            .with(plug_path([plugin, 'package.json']))
            .and_return true
        end
      end

      it 'should return two resources' do
        expect(described_class.instances.length).to eq(2)
      end
    end
  end # of describe instances

  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  describe 'flush' do
    before do
      described_class
        .stubs(:command).with(:plugin)
        .returns executable
    end

    let(:executable) { '/usr/share/kibana/bin/kibana-plugin' }

    let(:resource) do
      Puppet::Type.type(:kibana_plugin).new(
        :name     => 'x-pack',
        :provider => provider,
        :version  => '5.2.0'
      )
    end

    let(:provider) { described_class.new(:name => 'x-pack') }

    it 'installs plugins' do
      provider
        .expects(:execute)
        .with(
          [executable] + %w(install x-pack),
          :uid => 'kibana', :gid => 'kibana'
        )
      resource[:ensure] = :present
      provider.create
      provider.flush
    end

    it 'removes plugins' do
      provider
        .expects(:execute)
        .with(
          [executable] + %w(remove x-pack),
          :uid => 'kibana', :gid => 'kibana'
        )
      resource[:ensure] = :absent
      provider.destroy
      provider.flush
    end

    it 'updates plugins' do
      %w(install remove).each do |action|
        provider
          .expects(:execute)
          .with(
            [executable, action, 'x-pack'],
            :uid => 'kibana', :gid => 'kibana'
          )
      end
      resource[:ensure] = :present
      provider.version = '5.2.1'
      provider.flush
    end
  end
end # of describe puppet type
