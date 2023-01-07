# @summary The top-level kibana class that declares child classes for managing kibana.
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
# @param ensure State of Kibana on the system (simple present/absent/latest
#   or version number).
# @param config Hash of key-value pairs for Kibana's configuration file
# @param oss whether to manage OSS packages
# @param package_source Local path to package file for file (not repo) based installation
# @param plugindir
#   Directory containing kibana plugins.
#   Use this setting if your packages deviate from the norm (/usr/share/kibana/plugins)
# @param manage_repo Whether to manage the package manager repository
# @param status Service status
# @param kibana_user owner of kibana.yml
# @param kibana_group group of kibana.yml
#
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class kibana (
  Variant[Enum['present', 'absent', 'latest'], Pattern[/^\d([.]\d+)*(-[\d\w]+)?$/]] $ensure,
  Hash[String[1], Variant[String, Integer, Boolean, Array, Hash]] $config,
  Boolean $manage_repo,
  Boolean $oss,
  Optional[String] $package_source,
  Stdlib::Absolutepath $plugindir,
  Kibana::Status $status,
  String[1] $kibana_user = 'kibana',
  String[1] $kibana_group = 'kibana',
) {
  contain kibana::install
  contain kibana::config
  contain kibana::service

  if $manage_repo {
    contain elastic_stack::repo

    Class['elastic_stack::repo']
    -> Class['kibana::install']
  }

  # Catch absent values, otherwise default to present/installed ordering
  case $ensure {
    'absent': {
      Class['kibana::service']
      -> Class['kibana::config']
      -> Class['kibana::install']
    }
    default: {
      Class['kibana::install']
      -> Class['kibana::config']
      ~> Class['kibana::service']
    }
  }
}
