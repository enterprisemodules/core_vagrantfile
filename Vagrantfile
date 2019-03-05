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

def masterless_setup(config, srv)
  config.trigger.after :up do |trigger|
    #
    # Fix hostnames because Vagrant mixes it up.
    #
    if srv.vm.communicator == 'ssh'
      trigger.run_remote = {inline: <<~EOD}
        cat > /etc/hosts<< "EOF"
        127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
        #{server['public_ip']} #{hostname}.example.com #{hostname}
        EOF
        bash /vagrant/vm-scripts/install_puppet.sh
        bash /vagrant/vm-scripts/setup_puppet.sh
        /opt/puppetlabs/puppet/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp || true
      EOD
    else # Windows
      trigger.run_remote = {inline: <<~EOD}
        cd c:\\vagrant\\vm-scripts
        .\\install_puppet.ps1
        cd c:\\vagrant\\vm-scripts
        .\\setup_puppet.ps1
        iex "& 'C:\\Program Files\\Puppet Labs\\Puppet\\bin\\puppet' resource service puppet ensure=stopped"
        iex "& 'C:\\Program Files\\Puppet Labs\\Puppet\\bin\\puppet' resource service puppet ensure=stopped"
        iex "& 'C:\\Program Files\\Puppet Labs\\Puppet\\bin\\puppet' apply c:\\vagrant\\manifests\\site.pp -t"
      EOD
    end
  end

  config.trigger.after :provision do |trigger|
    if srv.vm.communicator == 'ssh'
      trigger.run_remote = {
        inline: "puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp || true"
      }
    end
  end
end

def puppet_master_setup(config, srv, puppet_installer)
  srv.vm.synced_folder '.', '/vagrant', owner: pe_puppet_user_id, group: pe_puppet_group_id
  srv.vm.provision :shell, inline: "/vagrant/modules/software/files/#{puppet_installer} -c /vagrant/pe.conf -y"
  #
  # For this vagrant setup, we make sure all nodes in the domain examples.com are autosigned. In production
  # you'dd want to explicitly confirm every node.
  #
  srv.vm.provision :shell, inline: "echo '*.example.com' > /etc/puppetlabs/puppet/autosign.conf"
  srv.vm.provision :shell, inline: "echo '*.local' >> /etc/puppetlabs/puppet/autosign.conf"
  srv.vm.provision :shell, inline: "echo '*.home' >> /etc/puppetlabs/puppet/autosign.conf"
  #
  # For now we stop the firewall. In the future we will add a nice puppet setup to the ports needed
  # for Puppet Enterprise to work correctly.
  #
  srv.vm.provision :shell, inline: 'systemctl stop firewalld.service'
  srv.vm.provision :shell, inline: 'systemctl disable firewalld.service'
  #
  # This script make's sure the vagrant paths's are symlinked to the places Puppet Enterprise looks for specific
  # modules, manifests and hiera data. This makes it easy to change these files on your host operating system.
  #
  srv.vm.provision :shell, path: 'vm-scripts/setup_puppet.sh'
  #
  # Make sure all plugins are synced to the puppetserver before exiting and stating
  # any agents
  #
  srv.vm.provision :shell, inline: 'service pe-puppetserver restart'
  srv.vm.provision :shell, inline: 'puppet agent -t || true'
end

def puppet_agent_setup(config, srv)
  #
  # First we need to instal the agent.
  #
  config.trigger.after :up do |trigger|
    #
    # Fix hostnames because Vagrant mixes it up.
    #
    if srv.vm.communicator == 'ssh'
      trigger.run_remote = {inline: <<~EOD}
        cat > /etc/hosts<< "EOF"
        127.0.0.1 localhost.localdomain localhost4 localhost4.localdomain4
        #{server['public_ip']} #{hostname}.example.com #{hostname}
        EOF
        curl -k https://master.example.com:8140/packages/current/install.bash | sudo bash
        #
        # The agent installation also automatically start's it. In production, this is what you want. For now we
        # want the first run to be interactive, so we see the output. Therefore, we stop the agent and wait
        # for it to be stopped before we start the interactive run
        #
        pkill -9 -f "puppet.*agent.*"
        /opt/puppetlabs/puppet/bin/puppet agent -t; exit 0
        #
        # After the interactive run is done, we restart the agent in a normal way.
        #
        systemctl start puppet
        EOD
      else
        trigger.run_remote = {inline: <<~EOD}
        Copy-Item -Path c:\\vagrant\\vm-scripts\\windows-hosts -Destination c:\\Windows\\System32\\Drivers\\etc\\hosts
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}; $webClient = New-Object System.Net.WebClient; $webClient.DownloadFile('https://wlsmaster.example.com:8140/packages/current/install.ps1', 'install.ps1');.\\install.ps1
        iex 'puppet resource service puppet ensure=stopped'
        iex 'puppet agent -t'
        EOD
    end
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
      srv.vm.communicator = server['protocol'] || 'ssh'
      srv.vm.box          = server['box']
      hostname            = name.split('-').last # First part contains type of node

      if srv.vm.communicator == 'ssh'
        srv.vm.hostname = "#{hostname}.example.com"
      else
        srv.vm.hostname = "#{hostname}"
        config.winrm.ssl_peer_verification = false
        config.winrm.retry_delay = 60
        config.winrm.retry_limit = 10
      end

      srv.vm.network 'private_network', ip: server['public_ip'] if server['public_ip']
      srv.vm.network 'private_network', ip: server['private_ip'], virtualbox__intnet: true if server['private_ip']

      srv.vm.synced_folder '.', '/vagrant', type: :virtualbox

      case server['type']
      when 'masterless'
        masterless_setup(config, srv)
      when 'pe-master'
        puppet_master_setup(config, srv, puppet_installer)
      when 'pe-agent'
        puppet_agent_setup(config, srv)
      end

      config.trigger.before :up do
      end

      config.trigger.after :up do
      end

      config.trigger.after :destroy do
      end

    end
  end
end
