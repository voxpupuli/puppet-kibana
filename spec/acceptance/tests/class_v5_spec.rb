# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'helpers/acceptance/tests/class_shared_examples'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'kibana class v5' do
  let(:plugin)         { 'health_metric_vis' }
  let(:plugin_version) { '0.3.4' }
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

  let(:plugin_url) { "file:///tmp/#{plugin}-#{plugin_version}.zip" }

  before do
    source = "https://github.com/DeanF/#{plugin}/releases/download/v#{plugin_version}/#{plugin}-#{version.split('-').first}.zip"
    on default, "curl -fsSL -o /tmp/#{plugin}-#{plugin_version}.zip #{source}"
  end

  include_examples 'class manifests',
                   '/usr/share/kibana/plugins/health_metric_vis/package.json',
                   '0.3.5'
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
