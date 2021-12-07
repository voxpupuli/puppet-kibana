# frozen_string_literal: true

require 'rspec/retry'

require_relative '../../spec_utilities'

ENV['PUPPET_INSTALL_TYPE'] = 'agent' if ENV['PUPPET_INSTALL_TYPE'].nil?

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

  c.add_setting :is_snapshot
  c.is_snapshot = c.files_to_run.any? { |fn| fn.include? 'snapshot' }

  c.add_setting :oss

  # Copy over the snapshot package if we're running snapshot tests
  if c.is_snapshot && !c.pkg_ext.nil?
    c.add_setting :snapshot_file
    c.snapshot_file = "kibana-snapshot.#{c.pkg_ext}"

    c.add_setting :snapshot_version
    c.snapshot_version = File.readlink(artifact(c.snapshot_file)).match(%r{kibana(?:-oss)?-(?<v>.*)[.][a-z]+})[:v]

    c.oss = (!File.readlink(artifact(c.snapshot_file)).match(%r{-oss}).nil?)
  else
    c.oss = false
  end

  # Configure all nodes in nodeset
  c.before :suite do
    if c.is_snapshot
      hosts.each do |host|
        scp_to host, artifact(c.snapshot_file), "/tmp/#{c.snapshot_file}"
      end
    end
  end

  c.around :each, :api do |example|
    # The initial optimization startup time of Kibana is _incredibly_ slow,
    # so we need to be pretty generous with how we retry API call attempts.
    example.run_with_retry retry: 10, retry_wait: 5
  end
end
