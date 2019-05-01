#
# This is remote script that fetches newest Vagrant config from core_vagrantfile
# repository and executes its code.
# Replace content of Vagrantfile in demo repostory with this script.
#
require 'net/http'

# $SAFE = 1 # SAFE 1 is not working with #require

uri = URI('https://raw.githubusercontent.com/enterprisemodules/core_vagrantfile/master/Vagrantfile')
vagrant_code = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
  request = Net::HTTP::Get.new uri.request_uri
  response = http.request request # Net::HTTPResponse object

  response.body
end

# EVAL IS NEVER SECURE!
eval(vagrant_code)
