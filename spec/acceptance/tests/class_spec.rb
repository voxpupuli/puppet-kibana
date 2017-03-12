require 'spec_helper_acceptance'

describe 'kibana class' do
  let(:plugin_version) { '0.3.4' }
  let(:port)           { 5602 }

  {
    '5.2.0' => '5.x'
  }.each do |v, r|
    let(:version) { v }
    let(:repo_version) { r }

    let(:manifest) do
      <<-EOS
        class { 'kibana':
          ensure => '#{version}',
          config => {
            'server.host' => '0.0.0.0',
            'server.port' => #{port},
          },
          repo_version => '#{repo_version}',
        }

        kibana_plugin { 'health_metric_vis':
          ensure  => 'present',
          url     => 'https://github.com/DeanF/health_metric_vis/releases/download/v#{plugin_version}/health_metric_vis-#{version}.zip',
          version => '#{plugin_version}',
        }
      EOS
    end

    describe "version #{v}" do
      context 'example manifest' do
        it { apply_manifest(manifest, :catch_failures => true) }
        it { apply_manifest(manifest, :catch_changes  => true) }

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

        it { apply_manifest(manifest, :catch_failures => true) }
        it { apply_manifest(manifest, :catch_changes  => true) }

        describe file('/usr/share/kibana/plugins/health_metric_vis/package.json') do
          its(:content_as_json) { should include('version' => plugin_version) }
        end
      end

      context 'removal' do
        let(:manifest) do
          <<-EOS
            class { 'kibana':
              ensure => absent,
            }
          EOS
        end

        it 'should apply cleanly' do
          apply_manifest(
            'kibana_plugin{"health_metric_vis": ensure => absent} ->' + manifest,
            :catch_failures => true
          )
        end

        it 'is idempotent' do
          apply_manifest(manifest, :catch_changes => true)
        end

        describe package('kibana') do
          it { should_not be_installed }
        end

        describe service('kibana') do
          it { should_not be_enabled }
          it { should_not be_running }
        end

        describe port(port) { it { should_not be_listening } }
      end
    end
  end
end
