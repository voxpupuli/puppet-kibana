# Class: kibana::config
#
# This class is called from kibana for service config.
#
class kibana::config {

  $config = $::kibana::config

  file { '/etc/kibana/kibana.yml':
    content => template("${module_name}/etc/kibana/kibana.yml.erb"),
  }
}
