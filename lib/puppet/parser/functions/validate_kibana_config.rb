# Extra third-party functions.
module Puppet::Parser::Functions
  newfunction(:validate_kibana_config, :doc => <<-'ENDHEREDOC') do |args|
    Validate that the Kibana config hash contains keys and values that are valid data types.
    Keys must be strings at least 1 character long and values must be either integers, booleans, arrays or strings at least 1 character long.

    @param config [Hash] The config hash

    @example
        $config = { 'server.host' => '0.0.0.0' }
        validate_kibana_config($config)

    @return nil
    ENDHEREDOC

    unless args.length == 1 then
      raise Puppet::ParseError, "validate_kibana_config(): wrong number of arguments (#{args.length}; must be 1)"
    end

    config = args[0]

    # check config is a hash
    unless config.is_a?(Hash)
      raise Puppet::ParseError, "validate_kibana_config(): #{config.inspect} is not a Hash.  It looks to be a #{config.class}"
    end

    # check each key => value pair is valid
    config.each do |key, value|
      unless key.is_a?(String) && !key.empty? && !key.nil?
        raise Puppet::ParseError, "validate_kibana_config(): config key of '#{key}' is not a String or zero length"
      end

      unless value.is_a?(Integer) || value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(Array) || (value.is_a?(String) && !value.empty? && !value.nil?)
        raise Puppet::ParseError, "validate_kibana_config(): Value of config key '#{key}' is not an Integer, Boolean, Array of String greater than zero length"
      end
    end
  end
end
