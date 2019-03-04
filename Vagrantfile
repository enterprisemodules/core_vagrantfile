require 'yaml'

VAGRANTFILE_API_VERSION = '2'.freeze

# Raises missing plugins
def plugin_error(plugin_name)
  unless Vagrant.has_plugin?(plugin_name)
    raise "#{plugin_name} is not installed, please run: vagrant plugin " \
          "install #{plugin_name}"
  end
end

# Read YAML file with box details
servers            = YAML.load_file('servers.yaml')
pe_puppet_user_id  = 495
pe_puppet_group_id = 496
vagrant_root       = File.dirname(__FILE__)
home               = ENV['HOME']
add_timestamp      = false

#
# This routine will read a ~/.software.yaml fileand make links to all the software defined.
#
def link_software(server)
  return nil unless server

  # Read YAML file with box details
  software_file = server['software'] ? server['software'] : []
  return nil if software_file == []

  if File.exist?(software_file)
    software_definition = YAML.load_file(software_file)
    software_locations = software_definition.fetch('software_locations') do
      raise "#{software_file} should contain key 'software_locations'"
    end
    raise "software_locations key in #{software_file} should contain array" unless software_locations.is_a?(Array)
  else
    software_locations = []
  end
  software_locations.unshift('./software') # Do local stuff first
  unless File.exist?('./modules/software/files')
    FileUtils.mkdir_p('./modules/software/files')
  end
  software_locations.each { |dir| link_sync(dir, './modules/software/files') }
end

#
# Link filename to target destination
#
def link_sync(dir, target)
  Dir.glob("#{dir}/*").each do |file|
    file_name = File.basename(file)
    if File.directory?(file)
      FileUtils.mkdir("#{target}/#{file_name}") unless File.exist?("#{target}/#{file_name}")
      link_sync(file, "#{target}/#{file_name}")
      next
    end
    full_target = "#{target}/#{file_name}"
    next if File.exist?(full_target)
    puts "Linking file #{file} to #{full_target}..."
    FileUtils.ln(file, full_target)
  end
end

#
# Vagrant setup
#
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false

  servers.each do |name, server|
    # Link software to server
    link_software(server)
    # Fetch puppet installer version
    puppet_installer = server['puppet_installer']
    # config
    config.vm.define name do |srv|
      srv.vm.box = server['box']
      hostname = name.split('-').last # First part contains type of node
      srv.vm.hostname = "#{hostname}.example.com"
      srv.vm.network 'private_network', ip: server['public_ip']
      srv.vm.network 'private_network', ip: server['private_ip'], virtualbox__intnet: true
      srv.vm.synced_folder '.', '/vagrant', type: :virtualbox

      config.trigger.before :up do
      end

      config.trigger.after :up do
      end

      config.trigger.after :destroy do
      end

    end
  end
end
