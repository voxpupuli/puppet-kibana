require 'spec_helper_acceptance'

describe 'kibana class' do
  let(:version) { '5.2.0' }
  let(:plugin_version) { '0.3.4' }
  let(:port) { 5602 }

  let(:manifest) do
    <<-EOS
      class { 'kibana':
        ensure => '#{version}',
        config => {
          'server.host' => '0.0.0.0',
          'server.port' => #{port},
        }
      }

      kibana_plugin { 'health_metric_vis':
        ensure  => 'present',
        url     => 'https://github.com/DeanF/health_metric_vis/releases/download/v#{plugin_version}/health_metric_vis-5.2.0.zip',
        version => '#{plugin_version}',
      }
    EOS
  end

  context 'example manifest' do
    it 'should work idempotently with no errors' do
      apply_manifest(manifest, :catch_failures => true)
      apply_manifest(manifest, :catch_changes  => true)
    end

    describe package('kibana') do
      it { is_expected.to be_installed }
    end

    describe service('kibana') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(port) { it { should be_listening } }

    describe server :container do
      describe http('http://localhost:5602') do
        it('returns OK', :api) { expect(response.status).to eq(200) }
        it('is live', :api) { expect(response['kbn-name']).to eq('kibana') }
        it 'installs the correct version', :api do
          expect(response['kbn-version']).to eq(version)
        end
      end
    end
  end

  context 'plugin upgrades' do
    let(:plugin_version) { '0.3.5' }

    it 'should work idempotently with no errors' do
      apply_manifest(manifest, :catch_failures => true)
      apply_manifest(manifest, :catch_changes  => true)
    end

    describe file('/usr/share/kibana/plugins/health_metric_vis/package.json') do
      its(:content_as_json) { should include('version' => plugin_version) }
    end
  end

  context 'removal' do
    it 'should apply cleanly' do
      manifest = <<-EOS
        kibana_plugin { 'health_metric_vis': ensure => absent } ->
        class { 'kibana':
          ensure => absent,
        }
      EOS

      apply_manifest(manifest, :catch_failures => true)
    end

    it 'is idempotent' do
      manifest = <<-EOS
        class { 'kibana':
          ensure => absent,
        }
      EOS

      apply_manifest(manifest, :catch_changes => true)
    end

    describe package('kibana') do
      it { should_not be_installed }
    end

    describe service('kibana') do
      it { should_not be_enabled }
      it { should_not be_running }
    end

    describe port(@port) { it { should_not be_listening } }
  end
end
