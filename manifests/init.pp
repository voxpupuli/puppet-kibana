# Class: kibana
#
# The top-level kibana class that declares child classes for managing kibana.
#
# @example Basic installation
#   class { 'kibana' : }
#
# @example Module removal
#   class { 'kibana' : ensure => absent }
#
# @example Installing a specific version
#   class { 'kibana' : ensure => '5.2.1' }
#
# @example Keep latest version of Kibana installed
#   class { 'kibana' : ensure => 'latest' }
#
# @example Setting a configuration file value
#   class { 'kibana' : config => { 'server.port' => 5602 } }
#
# @param ensure [String] State of Kibana on the system (simple present/absent/latest
#   or version number).
# @param config [Hash] Hash of key-value pairs for Kibana's configuration file
# @param manage_repo [Boolean] Whether to manage the package manager repository
# @param repo_key_id [String] Trusted GPG Key ID for package repository
# @param repo_key_source [String] Source for repo_key_id
# @param repo_priority [Integer] Optional repository priority
# @param repo_proxy [String] Proxy to use for repository access (yum only)
# @param repo_version [String] Repository major version to use
#
class kibana (
  $ensure          = 'present',
  $config          = {},
  $manage_repo     = true,
  $repo_key_id     = '46095ACC8548582C1A2699A9D27D666CD88E42B4',
  $repo_key_source = 'https://artifacts.elastic.co/GPG-KEY-elasticsearch',
  $repo_priority   = undef,
  $repo_proxy      = undef,
  $repo_version    = '5.x',
) {

  validate_string($ensure,
                  $repo_key_id,
                  $repo_key_source,
                  $repo_proxy,
                  $repo_version)

  validate_kibana_config($config)

  validate_bool($manage_repo)

  if $repo_priority != undef {
    validate_integer($repo_priority)
  }

  if !($ensure in ['present', 'absent', 'latest']) and $ensure !~ /^\d([.]\d+)*(-[\d\w]+)?$/ {
    fail('Invalid value for ensure')
  }

  if !($repo_version in ['5.x']) and $repo_version !~ /^4\.(1|[4-6])$/ {
    fail('Invalid value for repo_version')
  }

  class { '::kibana::install': }
  class { '::kibana::config': }
  class { '::kibana::service': }

  # Catch absent values, otherwise default to present/installed ordering
  case $ensure {
    'absent': {
      Class['::kibana::service']
        -> Class['::kibana::config']
        -> Class['::kibana::install']
    }
    default: {
      Class['::kibana::install']
        -> Class['::kibana::config']
        ~> Class['::kibana::service']
    }
  }
}
