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
define kibana::service::systemd (
  Enum['absent', 'present'] $ensure             = $kibana::ensure,
  Hash                      $init_defaults      = {},
  Optional[String]          $init_defaults_file = undef,
  String                    $init_template      = "${module_name}/etc/systemd/system/kibana.service.erb",
  Kibana::Status            $status             = $kibana::status,
) {

  #### Service management

  if $ensure == 'present' {

    case $status {
      # make sure service is currently running, start it on boot
      'enabled': {
        $service_ensure = 'running'
        $service_enable = true
      }
      # make sure service is currently stopped, do not start it on boot
      'disabled': {
        $service_ensure = 'stopped'
        $service_enable = false
      }
      # make sure service is currently running, do not start it on boot
      'running': {
        $service_ensure = 'running'
        $service_enable = false
      }
      # do not start service on boot, do not care whether currently running
      # or not
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      default: { }
    }
  } else {
    # make sure the service is stopped and disabled
    $service_ensure = 'stopped'
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

  $notify_service = $kibana::restart_config_change ? {
    true  => [ Exec["systemd_reload_${name}"], Service[$name] ],
    false => Exec["systemd_reload_${name}"]
  }

  if ($ensure == 'present') {

    # Defaults file, either from file source or from hash to augeas commands
    if ($init_defaults_file != undef) {
      file { "${kibana::defaults_location}/${name}":
        ensure => $ensure,
        source => $init_defaults_file,
        owner  => 'root',
        group  => '0',
        mode   => '0644',
        before => Service[$name],
        notify => $notify_service,
      }

    } else {

      augeas { "defaults_${name}":
        incl    => "${kibana::defaults_location}/${name}",
        lens    => 'Shellvars.lns',
        changes => template("${module_name}/etc/sysconfig/defaults.erb"),
        before  => Service[$name],
        notify  => $notify_service,
      }

    }

    $kibana_user = $::kibana::kibana_user
    $kibana_group = $::kibana::kibana_group
    $homedir = $::kibana::homedir
    $configdir = $::kibana::configdir
    file { "${kibana::systemd_service_path}/${name}.service":
      ensure  => $ensure,
      content => template("${module_name}/etc/systemd/system/kibana.service.erb"),
      owner   => 'root',
      group   => 'root',
      before  => Service[$name],
      notify  => $notify_service,
    }

    $service_require = Exec["systemd_reload_${name}"]

  } else { # absent

    file { "${kibana::systemd_service_path}/${name}.service":
      ensure    => 'absent',
      subscribe => Service[$name],
      notify    => Exec["systemd_reload_${name}"],
    }

    file { "${kibana::defaults_location}/${name}":
      ensure    => 'absent',
      subscribe => Service[$name],
      notify    => Exec["systemd_reload_${name}"],
    }

    $service_require = undef
  }

  exec { "systemd_reload_${name}":
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # action
  service { $name:
    ensure   => $service_ensure,
    enable   => $service_enable,
    provider => 'systemd',
    require  => $service_require,
  }
}
