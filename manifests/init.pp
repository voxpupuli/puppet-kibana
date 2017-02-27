# Class: kibana
#
# The top-level kibana class that declares child classes for managing kibana.
#
# @example Basic installation
#   class { 'kibana' : }
#
# @param ensure Whether kibana should be present or absent.
# @param config Hash of key-value pairs for Kibana's configuration file
# @param manage_repo Whether to manage the package manager repository
# @param repo_key_id Trusted GPG Key ID for package repository
# @param repo_key_source Source for repo_key_id
# @param repo_priority Optional repository priority
# @param repo_proxy Proxy to use for repository access (yum only)
# @param repo_version Repository major version to use
#
class kibana (
  Enum['present', 'absent'] $ensure              = $::kibana::params::ensure,
  Hash[String, Variant[String, Integer]] $config = {},
  Boolean $manage_repo                           = $::kibana::params::manage_repo,
  String $repo_key_id                            = $::kibana::params::repo_key_id,
  String $repo_key_source                        = $::kibana::params::repo_key_source,
  Optional[Integer] $repo_priority               = undef,
  Optional[String] $repo_proxy                   = undef,
  Enum['5.x'] $repo_version                      = $::kibana::params::repo_version,
) inherits ::kibana::params {

  class { '::kibana::install': } ->
  class { '::kibana::config': } ~>
  class { '::kibana::service': }
}
