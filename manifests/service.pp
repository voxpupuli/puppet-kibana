# Class: kibana::service
#
# This class is meant to be called from kibana.
# It ensure the service is running.
#
class kibana::service {

  $_ensure = $::kibana::ensure == 'present'
  $_enable = $::kibana::ensure == 'present'

  service { 'kibana':
    ensure => $_ensure,
    enable => $_enable,
  }
}
