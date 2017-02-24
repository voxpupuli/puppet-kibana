# == Class kibana::params
#
# This class is meant to be called from the ::kibana class.
# It sets default variables according to platform.
#
class kibana::params {
  $ensure = 'present'
  $manage_repo = true
  $repo_key_id = '46095ACC8548582C1A2699A9D27D666CD88E42B4'
  $repo_key_source = 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
  $repo_version = '5.x'

  case $::osfamily {
    'Debian': { }
    'RedHat', 'Amazon': { }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
