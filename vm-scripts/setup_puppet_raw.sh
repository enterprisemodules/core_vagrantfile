ln -s /vagrant/modules/software/files /software # Only on vagrant
NODENAME=mqiib01.example.com

echo 'Installing required puppet agent rpm...'
yum install /software/puppet-agent-1.9.3-1.el7.x86_64.rpm unzip -y

echo 'unpack puppet code...'
cd /software
unzip puppet_setup -d /etc/puppetlabs/code/environments/production

echo 'Setting up hiera directories'
cp /etc/puppetlabs/code/environments/production/hiera.yaml /etc/puppetlabs/code/hiera.yaml

echo 'setting up node'
mv /etc/puppetlabs/code/environments/production/hieradata/nodes/node.yaml /etc/puppetlabs/code/environments/production/hieradata/nodes/$NODENAME.yaml

echo 'setting up entitlements'
cp /software/*.entitlements /etc/puppetlabs/code/environments/production/modules/em_license/files/
