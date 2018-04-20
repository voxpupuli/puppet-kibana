# This class is called from the kibana class to manage installation.
# It is not meant to be called directly.
#
# @author Tyler Langlois <tyler.langlois@elastic.co>
#
class kibana::install {

  case $::kibana::ensure {
    'present': {
      $_ensure = $::kibana::version
      $repo_ensure = 'present'
      $dir_ensure = 'directory'
      $file_ensure = 'file'
      $optimize_require = Package[$::kibana::package_name]
    }
    'absent': {
      # Handle absent and latest
      $_ensure = $::kibana::ensure
      $repo_ensure = $::kibana::ensure
      $dir_ensure = $::kibana::ensure
      $file_ensure = $::kibana::ensure
      $optimize_require = undef
    }
    default: {
      # Handle version number
      $_ensure = $::kibana::ensure
      $repo_ensure = 'present'
      $dir_ensure = 'directory'
      $file_ensure = 'file'
      $optimize_require = Package[$::kibana::package_name]
    }
  }

  if $::kibana::manage_repo {
    if $::kibana::repo_version =~ /^4[.]/ {
      $_repo_baseurl = "https://packages.elastic.co/kibana/${::kibana::repo_version}"
      $_repo_path = $facts['os']['family'] ? {
        'Debian'          => 'debian',
        /(RedHat|Amazon)/ => 'centos'
      }
    } else {
      $_repo_baseurl = "https://artifacts.elastic.co/packages/${::kibana::repo_version}"
      $_repo_path = $facts['os']['family'] ? {
        'Debian'          => 'apt',
        /(RedHat|Amazon)/ => 'yum'
      }
    }

    case $facts['os']['family'] {
      'Debian': {
        include ::apt
        Class['apt::update'] -> Package[$::kibana::package_name]

        apt::source { 'kibana':
          ensure   => $repo_ensure,
          location => "${_repo_baseurl}/${_repo_path}",
          release  => 'stable',
          repos    => 'main',
          key      => {
            'id'     => $::kibana::repo_key_id,
            'source' => $::kibana::repo_key_source,
          },
          include  => {
            'src' => false,
            'deb' => true,
          },
          pin      => $::kibana::repo_priority,
          before   => Package[$::kibana::package_name],
        }
      }
      'RedHat', 'Amazon': {
        yumrepo { 'kibana':
          ensure   => $repo_ensure,
          descr    => "Elastic ${::kibana::repo_version} repository",
          baseurl  => "${_repo_baseurl}/${_repo_path}",
          gpgcheck => 1,
          gpgkey   => $::kibana::repo_key_source,
          enabled  => 1,
          proxy    => $::kibana::repo_proxy,
          priority => $::kibana::repo_priority,
          before   => Package[$::kibana::package_name],
        }
        ~> exec { 'kibana_yumrepo_yum_clean':
          command     => 'yum clean metadata expire-cache --disablerepo="*" --enablerepo="kibana"',
          path        => [ '/bin', '/usr/bin' ],
          refreshonly => true,
          returns     => [0, 1],
          before      => Package[$::kibana::package_name],
        }
      }
      default: {
        fail("unsupported operating system family ${facts['os']['family']}")
      }
    }
  }

  if $::kibana::package_source != undef {
    case $facts['os']['family'] {
      'Debian': { Package[$::kibana::package_name] { provider => 'dpkg' } }
      'RedHat': { Package[$::kibana::package_name] { provider => 'rpm' } }
      default: { fail("unsupported parameter 'source' set for osfamily ${facts['os']['family']}") }
    }
  }


  package { $::kibana::package_name:
    ensure => $_ensure,
    source => $::kibana::package_source,
  }

  if $::kibana::homedir {
    $homedir = $::kibana::homedir
  } else {
    if $::kibana::repo_version =~ /^4[.]/  {
      $homedir = '/opt/kibana'
    } else {
      $homedir = '/usr/share/kibana'
    }
  }


  file{ "${homedir}/optimize":
    ensure  => $dir_ensure,
    owner   => $::kibana::kibana_user,
    group   => $::kibana::kibana_group,
    mode    => '0775',
    force   => true,
    require => $optimize_require,
  }

  file{ "${homedir}/optimize/.babelcache":
    ensure  => $file_ensure,
    owner   => $::kibana::kibana_user,
    group   => $::kibana::kibana_group,
    mode    => '0664',
    require => File["${homedir}/optimize"],
  }

  $pid_dir = $::kibana::pid_dir
  file{ $pid_dir:
    ensure  => $dir_ensure,
    owner   => $::kibana::kibana_user,
    group   => $::kibana::kibana_group,
    mode    => '0775',
    force   => true,
    require => $optimize_require,
  }
}
