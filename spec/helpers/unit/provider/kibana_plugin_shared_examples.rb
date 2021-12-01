# frozen_string_literal: true

require 'json'

shared_examples 'kibana plugin provider' do
  describe 'instances' do
    it 'has an instance method' do
      expect(described_class).to respond_to :instances
    end

    context 'without plugins' do
      before do
        allow(Dir).to receive(:[]).and_return %w[. ..]
      end

      it 'returns no resources' do
        expect(described_class.instances.size).to eq(0)
      end
    end

    context 'with one plugin' do
      subject { described_class.instances.first }

      before do
        allow(Dir).to receive(:[]).and_return [File.join(plugin_path, plugin_one[:name])]
        allow(File).to receive(:read).
          with(File.join(plugin_path, plugin_one[:name], 'package.json')).
          and_return JSON.dump(name: plugin_one[:name], version: plugin_one[:version])
        allow(File).to receive(:exist?).
          with(File.join(plugin_path, plugin_one[:name], 'package.json')).
          and_return true
      end

      it { expect(subject).to exist }
      it { expect(subject.name).to eq(plugin_one[:name]) }
      it { expect(subject.version).to eq(plugin_one[:version]) }
    end

    context 'with multiple plugins' do
      before do
        allow(Dir).
          to(receive(:[])).
          and_return([plugin_one, plugin_two].map { |p| File.join(plugin_path, p[:name]) })
        [plugin_one, plugin_two].each do |plugin|
          allow(File).to receive(:read).
            with(File.join(plugin_path, plugin[:name], 'package.json')).
            and_return JSON.dump(name: plugin[:name], verison: plugin[:version])
          allow(File).to receive(:exist?).
            with(File.join(plugin_path, plugin[:name], 'package.json')).
            and_return true
        end
      end

      it 'returns two resources' do
        expect(described_class.instances.length).to eq(2)
      end
    end
  end

  describe 'prefetch' do
    it 'has a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  describe 'flush' do
    before do
      allow(described_class).
        to receive(:command).with(:plugin).
        and_return executable
    end

    let(:install_name) do
      if resource[:organization].nil?
        resource[:name]
      else
        [resource[:organization], resource[:name], resource[:version]].join('/')
      end
    end

    it 'installs plugins' do
      allow(provider).to(
        receive(:execute).
          with(
            [executable] + install_args + [install_name],
            uid: 'kibana', gid: 'kibana'
          ).
          and_return(
            Puppet::Util::Execution::ProcessOutput.new('success', 0)
          )
      )
      resource[:ensure] = :present
      provider.create
      provider.flush
      expect(provider).to(
        have_received(:execute).
          with(
            [executable] + install_args + [install_name],
            uid: 'kibana', gid: 'kibana'
          )
      )
    end

    it 'removes plugins' do
      allow(provider).to(
        receive(:execute).
          with(
            [executable] + remove_args + [resource[:name]],
            uid: 'kibana', gid: 'kibana'
          ).
          and_return(
            Puppet::Util::Execution::ProcessOutput.new('success', 0)
          )
      )
      resource[:ensure] = :absent
      provider.destroy
      provider.flush
      expect(provider).to(
        have_received(:execute).
          with(
            [executable] + remove_args + [resource[:name]],
            uid: 'kibana', gid: 'kibana'
          )
      )
    end

    it 'updates plugins' do
      allow(provider).to(
        receive(:execute).
          with(
            [executable] + install_args + [install_name],
            uid: 'kibana', gid: 'kibana'
          ).
          and_return(
            Puppet::Util::Execution::ProcessOutput.new('success', 0)
          )
      )
      allow(provider).to(
        receive(:execute).
          with(
            [executable] + remove_args + [resource[:name]],
            uid: 'kibana', gid: 'kibana'
          ).
          and_return(
            Puppet::Util::Execution::ProcessOutput.new('success', 0)
          )
      )
      resource[:ensure] = :present
      provider.version = plugin_one[:version]
      provider.flush
      expect(provider).to(
        have_received(:execute).
          with(
            [executable] + install_args + [install_name],
            uid: 'kibana', gid: 'kibana'
          )
      )
      expect(provider).to(
        have_received(:execute).
          with(
            [executable] + remove_args + [resource[:name]],
            uid: 'kibana', gid: 'kibana'
          )
      )
    end
  end

  describe 'command execution' do
    it 'causes catalog failures' do
      allow(provider).to receive(:execute).and_return(
        Puppet::Util::Execution::ProcessOutput.new('failed', 70)
      )
      resource[:ensure] = :present
      expect { provider.flush }.to raise_error(Puppet::Error)
      expect(provider).to have_received(:execute)
    end
  end
end
