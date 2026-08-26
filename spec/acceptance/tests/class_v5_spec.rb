# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'helpers/acceptance/tests/class_shared_examples'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'kibana class v5' do
  let(:plugin)         { 'enhanced-table' }
  let(:plugin_version) { '1.0.0' }
  let(:port)           { 5602 }
  let(:version)        { fact('osfamily') == 'RedHat' ? '5.6.16-1' : '5.6.16' }

  let(:manifest) do
    <<-MANIFEST
        class { 'elastic_stack::repo':
          version => 5,
        }

        class { 'kibana':
          ensure => '#{version}',
          config => {
            'server.host' => '0.0.0.0',
            'server.port' => #{port},
          },
        }

        kibana_plugin { '#{plugin}':
          ensure  => 'present',
          url     => '#{plugin_url}',
          version => '#{plugin_version}',
        }
    MANIFEST
  end

  let(:plugin_url) do
    "https://github.com/fbaligand/kibana-#{plugin}/releases/download/v#{plugin_version}/#{plugin}-#{plugin_version}_#{version.split('-').first}.zip"
  end

  include_examples 'class manifests',
                   '/usr/share/kibana/plugins/enhanced-table/package.json',
                   '1.1.0'
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
