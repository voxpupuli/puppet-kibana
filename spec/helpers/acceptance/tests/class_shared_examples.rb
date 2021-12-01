# frozen_string_literal: true

require 'helpers/acceptance/tests/basic_shared_examples'

shared_examples 'class manifests' do |plugin_json_file, plugin_upgrade|
  include_examples 'basic acceptance'

  context 'plugin upgrades' do
    let(:plugin_version) { plugin_upgrade }

    it { apply_manifest(manifest, catch_failures: true) }
    it { apply_manifest(manifest, catch_changes: true) }

    describe file(plugin_json_file) do
      its(:content_as_json) { is_expected.to include('version' => plugin_version) }
    end
  end

  context 'removal' do
    let(:manifest) do
      <<-MANIFEST
        class { 'kibana':
          ensure => absent,
        }
      MANIFEST
    end

    it 'applies cleanly' do
      apply_manifest(
        "kibana_plugin { '#{plugin}': ensure => absent } ->" + manifest,
        catch_failures: true
      )
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end

    describe package('kibana') do
      it { is_expected.not_to be_installed }
    end

    describe service('kibana') do
      it { is_expected.not_to be_enabled }
      it { is_expected.not_to be_running }
    end

    describe port(5602) { it { is_expected.not_to be_listening } }
  end
end
