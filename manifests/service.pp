# Class: kibana::service
#
# This class is meant to be called from kibana.
# It ensure the service is running.
#
class kibana::service {

  service { 'kibana':
    ensure => true,
    enable => true,
  }
}
