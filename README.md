[![Enterprise Modules](https://raw.githubusercontent.com/enterprisemodules/public_images/master/banner1.jpg)](https://www.enterprisemodules.com)
# Core Vagrantfile

This is common Vagrantfile to be used in all of the demo solutions.

Readme contains Vagrantfile which reads configuration data from servers.yaml and
Puppetfile.

To create setup based on this repository also vm-scripts folder needs to be
included.

## Web Fetch Vagrantfile

This repository hold also INSECURE script which pulls this repostiory
Vagrantfile from master branch and executes its code.

If you want to use it please replace content of `Vagrantfile` with
`web_fetch_vagrantfile.rb`
