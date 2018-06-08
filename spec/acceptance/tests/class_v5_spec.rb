require 'spec_helper_acceptance'
require 'helpers/acceptance/tests/class_shared_examples.rb'

describe 'kibana class v5' do
  let(:plugin)         { 'x-pack' }
  let(:plugin_version) { version.chomp '-1' }
  let(:port)           { 5602 }
  let(:version)        { fact('osfamily') == 'RedHat' ? '5.6.9-1' : '5.6.9' }

  let(:manifest) do
    <<-MANIFEST
        class { 'kibana':
          ensure => '#{version}',
          config => {
            'server.host' => '0.0.0.0',
            'server.port' => #{port},
          },
          repo_version => '5.x',
        }

        kibana_plugin { '#{plugin}':
          ensure  => 'present',
          version => '#{plugin_version}',
        }
      MANIFEST
  end

  include_examples 'class manifests',
                   '/usr/share/kibana/plugins/x-pack/package.json',
                   false,
                   '/login'
end
