# Original Author:: Matt Ray <matt@opscode.com>
# Original Cookbook:: pxe_dust
# Author:: Scott Macfarlane
# Cookbook Name:: pxe
# Recipe:: installers
#
# Copyright 2012-2013 Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'net/http'

#location of the full stack installers
directory "#{node['pxe']['dir']}/opscode-full-stack" do
  mode '0755'
end

begin
  pxebag = data_bag('pxe')
  defaults = data_bag_item('pxe', 'default').merge(node['pxe']['defaults'])
rescue
  log "No 'pxe' data bag found" do
    level :warn
  end
end

pxebag.each do |id|
  image = defaults.merge(data_bag_item('pxe', id)).merge(node['pxe']['defaults'])

  platform = 'el'#image['platform']
  arch = image['arch']
  version = image['version'].to_i
  version = version > 6 ? 6 : version


  if image['bootstrap']
    http_proxy = image['bootstrap']['http_proxy']
    http_proxy_user = image['bootstrap']['http_proxy_user']
    http_proxy_pass = image['bootstrap']['http_proxy_pass']
    https_proxy = image['bootstrap']['https_proxy']
  end

  # only get the full stack installers to use
  rel_arch = case arch
             when 'ppc' then 'powerpc'
             when 'i386' then 'i686'
             else 'x86_64'
             end
  case version
  when /^6/
    release = "centos-6.0-#{rel_arch}"
  when /^7/
    release = "centos-6.0-#{rel_arch}"
  end

  directory "#{node['pxe']['dir']}/opscode-full-stack/#{release}" do
    mode 0755
  end

  installer = ''
  location = ''

  #for getting latest version of full stack installers
  Net::HTTP.start('www.getchef.com') do |http|
    Chef::Log.info("/chef/download?v=#{node['pxe']['chefversion']}&p=#{platform}&pv=#{version}&m=#{rel_arch}")
    response = http.get("/chef/download?v=#{node['pxe']['chefversion']}&p=#{platform}&pv=#{version}&m=#{rel_arch}")
    Chef::Log.info("Code = #{response.code}")
    location = response['location']
    Chef::Log.info("Omnitruck URL: #{location}")
    installer = location.split('/').last
    Chef::Log.debug("Omnitruck installer: #{installer}")
  end

  #download the full stack installer
  remote_file "#{node['pxe']['dir']}/opscode-full-stack/#{release}/#{installer}" do
    source location
    mode 0644
    action :create_if_missing
  end

  run_list = (image['run_list'] || '').split(',') #for supporting multiple items

  #Chef bootstrap script run by new installs
  template "#{node['pxe']['dir']}/#{id}-chef-bootstrap" do
    source 'chef-bootstrap.sh.erb'
    mode 0644
    variables(
      :release => release,
      :installer => installer,
      :interface => image['interface'] || 'eth0',
      :environment => image['environment'],
      :run_list => run_list
      )
  end

end

#link the validation_key where it can be downloaded
link "#{node['pxe']['dir']}/validation.pem" do
  to Chef::Config[:validation_key]
end
