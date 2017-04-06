# Define: kibana::validate_config
#
# Validate that the config hash is a valid data type

define kibana::validate_config(
  $config
) {
  $key = $title

  if !(is_string($key) and size($key) > 0) {
    fail('config contains invalid keys')
  }

  if !is_integer($config[$key]) and
    !is_bool($config[$key]) and
    !is_array($config[$key]) and
    !(is_string($config[$key]) and size($config[$key]) > 0) {
    fail('config contains invalid values')
  }
}
