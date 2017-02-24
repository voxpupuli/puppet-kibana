# Class: kibana::install
#
# This class is called from the ::kibana class to manage installation.
#
class kibana::install {

  $_repo_baseurl = "https://artifacts.elastic.co/packages/${::kibana::repo_version}"

  case $::osfamily {
    'Debian': {
      include ::apt
      package { 'apt-transport-https' :
        before => Class['apt::update'],
      }
      Class['apt::update'] -> Package['kibana']

      apt::source { 'kibana':
        ensure   => $::kibana::ensure,
        location => "${_repo_baseurl}/apt",
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
        before   => Package['kibana'],
      }
    }
    'RedHat', 'Amazon': {
      yumrepo { 'kibana':
        ensure   => $::kibana::ensure,
        descr    => "Elastic ${::kibana::repo_version} repository",
        baseurl  => "${_repo_baseurl}/yum",
        gpgcheck => 1,
        gpgkey   => $::kibana::repo_key_source,
        enabled  => 1,
        proxy    => $::kibana::repo_proxy,
        priority => $::kibana::repo_priority,
        before   => Package['kibana'],
      } ~>
      exec { 'kibana_yumrepo_yum_clean':
        command     => 'yum clean metadata expire-cache --disablerepo="*" --enablerepo="kibana"',
        path        => [ '/bin', '/usr/bin' ],
        refreshonly => true,
        returns     => [0, 1],
        before      => Package['kibana'],
      }
    }
    default: {
      fail("unsupported operating system family ${::osfamily}")
    }
  }

  package { 'kibana':
    ensure => $::kibana::ensure,
  }
}
