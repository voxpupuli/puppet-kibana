require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'infrataster/rspec'
require 'rspec/retry'
require 'spec_utilities'

ENV['PUPPET_INSTALL_TYPE'] = 'agent' if ENV['PUPPET_INSTALL_TYPE'].nil?

# Otherwise puppet defaults to /etc/puppetlabs/code
configure_defaults_on hosts, 'foss' unless ENV['PUPPET_INSTALL_TYPE'] == 'agent'

if ENV['PUPPET_INSTALL_TYPE'] == 'gem'
  install_puppet_from_gem_on(
    hosts,
    :version => (
      ENV['PUPPET_INSTALL_VERSION'] || ENV['PUPPET_VERSION'] || '~> 4.0'
    )
  )
else
  run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
end

# Define server names for API tests
Infrataster::Server.define(:docker) do |server|
  server.address = default_node[:ip]
  server.ssh = default_node[:ssh].tap { |s| s.delete :forward_agent }
end
Infrataster::Server.define(:container) do |server|
  server.address = default_node[:vm_ip] # this gets ignored anyway
  server.from = :docker
end

RSpec.configure do |c|
  # Project root
  # proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  c.add_setting :pkg_ext
  c.pkg_ext = case fact('osfamily')
              when 'Debian'
                'deb'
              when 'RedHat'
                'rpm'
              end

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    ['kibana', 'stdlib', ('apt' if c.pkg_ext == 'deb')].compact.each do |mod|
      install_dev_puppet_module(
        :module_name => mod,
        :source      => "spec/fixtures/modules/#{mod}"
      )
    end

    # Copy over the snapshot package if we're running snapshot tests
    if c.files_to_run.any? { |fn| fn.include? 'snapshot' } and !c.pkg_ext.nil?
      filename = "kibana-snapshot.#{c.pkg_ext}"
      hosts.each do |host|
        scp_to host, artifact(filename), "/tmp/#{filename}"
      end
      c.add_setting :snapshot_version
      c.snapshot_version = File.readlink(artifact(filename)).match(/kibana-(?<v>.*)-[^.]+[.][a-z]+/)[:v]
    end
  end

  c.around :each, :api do |example|
    example.run_with_retry retry: 3, retry_wait: 5
  end
end
