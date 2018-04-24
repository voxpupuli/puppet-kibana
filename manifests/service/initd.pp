# This class exists to coordinate all service management related actions,
# functionality and logical units in a central place.
#
# *Note*: "service" is the Puppet term and type for background processes
# in general and is used in a platform-independent way. E.g. "service" means
# "daemon" in relation to Unix-like systems.
#
# @param ensure
#   Controls if the managed resources shall be `present` or
#   `absent`. If set to `absent`, the managed software packages will being
#   uninstalled and any traces of the packages will be purged as well as
#   possible. This may include existing configuration files (the exact
#   behavior is provider). This is thus destructive and should be used with
#   care.
#
# @param init_defaults
#   Defaults file content in hash representation
#
# @param init_defaults_file
#   Defaults file as puppet resource
#
# @param init_template
#   Service file as a template
#
# @param status
#   Defines the status of the service. If set to `enabled`, the service is
#   started and will be enabled at boot time. If set to `disabled`, the
#   service is stopped and will not be started at boot time. If set to `running`,
#   the service is started but will not be enabled at boot time. You may use
#   this to start a service on the first Puppet run instead of the system startup.
#   If set to `unmanaged`, the service will not be started at boot time and Puppet
#   does not care whether the service is running or not. For example, this may
#   be useful if a cluster management software is used to decide when to start
#   the service plus assuring it is running on the desired node.
#
# @author Richard Pijnenburg <richard.pijnenburg@elasticsearch.com>
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
define kibana::service::initd (
  Enum['absent', 'present'] $ensure             = $kibana::ensure,
  Hash                      $init_defaults      = {},
  Optional[String]          $init_defaults_file = undef,
  String                    $init_template      = "${module_name}/etc/init.d/kibana.erb",
  Kibana::Status            $status             = $::kibana::status,
) {

  #### Service management

  if $ensure == 'present' {

    case $status {
      # make sure service is currently running, start it on boot
      'enabled': {
        $service_ensure = true
        $service_enable = true
      }
      # make sure service is currently stopped, do not start it on boot
      'disabled': {
        $service_ensure = false
        $service_enable = false
      }
      # make sure service is currently running, do not start it on boot
      'running': {
        $service_ensure = true
        $service_enable = false
      }
      # do not start service on boot, do not care whether currently running
      # or not
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      default: {
        fail('Invalid value for status')
      }
    }
  } else {
    # make sure the service is stopped and disabled
    $service_ensure = false
    $service_enable = false
  }

  if(has_key($init_defaults, 'user') and $init_defaults['user'] != $kibana::kibana_user) {
    fail('Found user setting for init_defaults but is not same as kibana_user setting. Please use kibana_user setting.')
  }

  $new_init_defaults = merge(
    {
      'user'   => $kibana::kibana_user,
      'group'  => $kibana::kibana_group,
      'chroot' => '/',
      'chdir'  => '/',
    },
    $init_defaults
  )

  $defaults_file = "${kibana::defaults_location}/${name}"
  if ($ensure == 'present') {

    # Defaults file, either from file source or from hash to augeas commands
    if ($init_defaults_file != undef) {
      file { $defaults_file:
        ensure => $ensure,
        source => $init_defaults_file,
        owner  => 'root',
        group  => '0',
        mode   => '0644',
        before => Service[$name],
      }

    } else {

      augeas { "defaults_${name}":
        incl    => $defaults_file,
        lens    => 'Shellvars.lns',
        changes => template("${module_name}/etc/sysconfig/defaults.erb"),
        before  => Service[$name],
      }

    }

    $kibana_user = $::kibana::kibana_user
    $kibana_group = $::kibana::kibana_group
    $pid_dir = $::kibana::pid_dir
    if $::kibana::homedir {
      $homedir = $::kibana::homedir
    } else {
      if $::kibana::repo_version =~ /^4[.]/  {
        $homedir = '/opt/kibana'
      } else {
        $homedir = '/usr/share/kibana'
      }
    }
    if $::kibana::configdir {
      $configdir = $::kibana::configdir
    } else {
      if $::kibana::repo_version =~ /^4[.]/  {
        $configdir = '/opt/kibana/config'
      } else {
        $configdir = '/etc/kibana'
      }
    }
    if $::kibana::logdir {
      $logdir = $::kibana::logdir
    } else {
      $logdir = '/var/log/kibana'
    }

    file { "${kibana::initd_service_path}/${name}":
      ensure  => $ensure,
      content => template($init_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      before  => Service[$name],
    }

  } else { # absent

    # Leaving file "${kibana::initd_service_path}/${name}" behind to make this idempotent

    file { $defaults_file:
      ensure    => 'absent',
      subscribe => Service[$name],
    }

  }

  # action
  service { $name:
    ensure => $service_ensure,
    enable => $service_enable,
  }
}
