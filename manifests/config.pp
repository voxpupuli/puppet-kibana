# Class: kibana::config
#
# This class is called from kibana for service config.
#
class kibana::config {

  $_ensure = $::kibana::ensure ? {
    'absent' => $::kibana::ensure,
    default  => 'file',
  }
  $config = $::kibana::config

  file { '/etc/kibana/kibana.yml':
    ensure  => $_ensure,
    content => template("${module_name}/etc/kibana/kibana.yml.erb"),
  }
}
