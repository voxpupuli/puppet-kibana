Puppet::Type.newtype(:kibana_plugin) do
  @doc = 'Manages Kibana plugins.'

  ensurable do
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

  # Issue install commands with kibana uid/gid once user and commands are
  # present
  autorequire(:package) do
    'kibana'
  end
end
