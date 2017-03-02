require 'json'

# rubocop:disable Metrics/AbcSize
Puppet::Type.type(:kibana_plugin).provide(:ruby) do
  desc 'Native command-line provider for Kibana plugins.'

  @home_dir = File.absolute_path(File.join(%w(/ usr share kibana)))
  @plugin_dir = File.join(@home_dir, 'plugins')

  commands :plugin => File.join(@home_dir, 'bin', 'kibana-plugin')

  def self.present_plugins
    Dir[File.join(@plugin_dir, '*')].select do |directory|
      not File.basename(directory).start_with? '.' \
        and File.exist? File.join(directory, 'package.json')
    end.map do |plugin|
      j = JSON.parse(File.read(File.join(plugin, 'package.json')))
      {
        :name => File.basename(plugin),
        :ensure => :present,
        :provider => name,
        :version => j['version']
      }
    end
  end

  def flush
    if @property_flush[:ensure] == :absent
      # Simply remove the plugin if it should be gone
      run_plugin ['remove', resource[:name]]
    else
      unless @property_flush[:version].nil?
        run_plugin ['remove', resource[:name]]
      end
      run_plugin ['install', plugin_url]
    end

    set_property_hash
  end

  def run_plugin(args)
    debug(
      execute([command(:plugin)] + args, :uid => 'kibana', :gid => 'kibana')
    )
  end

  def plugin_url
    resource[:url].nil? ? resource[:name] : resource[:url]
  end

  # The rest is normal provider boilerplate.

  mk_resource_methods

  def version=(new_version)
    @property_flush[:version] = new_version
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def set_property_hash
    @property_hash = self.class.present_plugins.detect do |p|
      p[:name] == resource[:name]
    end
  end

  def self.instances
    present_plugins.map do |plugin|
      new plugin
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end
end
