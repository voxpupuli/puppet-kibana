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
# @param ensure State of Kibana on the system (present or absent, latest or an
#   explicit version number are deprecated in favor of the version parameter
#   but are still supported)
# @param version Version number of the package (latest or version number)
# @param package_name name of the rpm or debian package, defaults to kibana
# @param config Hash of key-value pairs for Kibana's configuration file
# @param package_source Local path to package file for file (not repo) based installation
# @param manage_repo Whether to manage the package manager repository
# @param repo_key_id Trusted GPG Key ID for package repository
# @param repo_key_source Source for repo_key_id
# @param repo_priority Optional repository priority
# @param repo_proxy Proxy to use for repository access (yum only)
# @param repo_version Repository major version to use. Versions 5.x onward
#   follow the major.minor form (i.e., 6.x), while previous versions (for
#   version 4) can be 4.1, 4.4, 4.5, or 4.6.
# @param status Service status
#   The service resource type provider to use when managing elasticsearch instances.
# @param manage_service, manage the systemd service, defaults to false
# @param homedir home directory, defaults to /usr/share/kibana
# @param configdir configuration directory, defaults to /etc/kibana or /opt/kibana/config on 4.x
# @param datadir data not stored in elasticsearch is stored here, defaults to /var/lib/kibana
# @param kibana_user user to run the application as, defaults to kibana
# @param kibana_group group for the kibana user, defaults to kibana
# @param restart_config_change
#   Determines if the application should be automatically restarted
#   whenever the configuration changes. This includes the Kibana
#   configuration file, any service files, and defaults files.
#   Disabling automatic restarts on config changes may be desired in an
#   environment where you need to ensure restarts occur in a controlled/rolling
#   manner rather than during a Puppet run.
# @param defaults_location
#   Absolute path to directory containing init defaults file.
# @param pid_dir
#   Directory where the kibana process should write out its PID.
# @param systemd_service_path
#   Path to the directory in which to install systemd service units.
#
# @author Tyler Langlois <tyler.langlois@elastic.co>
# @author Joern Ott <joern.ott@ott-consult.de>
#
class kibana (
  Variant[Enum['present', 'absent', 'latest'], Pattern[/^\d([.]\d+)*(-[\d\w]+)?$/]] $ensure,
  String $version = 'latest',
  String $package_name = 'kibana',
  Hash[String[1], Variant[String[1], Integer, Boolean, Array]] $config,
  Boolean $manage_repo,
  Optional[String] $package_source,
  String $repo_key_id,
  String $repo_key_source,
  Optional[Integer] $repo_priority,
  Optional[String] $repo_proxy,
  Variant[Enum['5.x', '6.x'], Pattern[/^4\.(1|[4-6])$/]] $repo_version,
  Kibana::Status $status,
  Enum['init', 'openbsd', 'openrc', 'systemd'] $service_provider,
  String $homedir = '/usr/share/kibana',
  Optional[String] $configdir = undef,
  String $datadir = '/var/lib/kibana',
  String $kibana_user = 'kibana',
  String $kibana_group = 'kibana',
  Boolean $restart_config_change = false,
  Optional[Stdlib::Absolutepath] $defaults_location,
  Optional[Stdlib::Absolutepath] $pid_dir,
  Boolean $manage_service = false,
  Stdlib::Absolutepath $systemd_service_path,
  String $service_name = 'kibana',
  Optional[Hash] $init_defaults,
) {

  contain ::kibana::install
  contain ::kibana::config

  if $manage_service {
    if $ensure == 'absent' {
      $service_ensure = 'absent'
      $service_before = Class['::kibana::config']
      $service_subscribe = []
    } else {
      $service_ensure = 'present'
      $service_before = []
      $service_subscribe = Class['::kibana::install']
    }
    kibana::service{$service_name:
      ensure        => $service_ensure,
      init_defaults => $init_defaults,
      before        => $service_before,
      subscribe     => $service_subscribe,
    }
  }

  # Catch absent values, otherwise default to present/installed ordering
  case $ensure {
    'absent': {
        Class['::kibana::config']
        -> Class['::kibana::install']
    }
    default: {
      Class['::kibana::install']
      -> Class['::kibana::config']
      ~> Class['::kibana::service']
    }
  }
}
