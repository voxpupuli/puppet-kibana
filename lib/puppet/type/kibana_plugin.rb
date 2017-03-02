Puppet::Type.newtype(:kibana_plugin) do
  @doc = 'Manages Kibana plugins.'

  ensurable do
    desc 'Whether the plugin should be present or absent.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Simple name of the Kibana plugin (not a URL or file path).'
  end

  newparam(:url) do
    desc 'URL to use when fetching plugin for installation.'
  end

  newproperty(:version) do
    desc 'Installed plugin version.'
  end
end
