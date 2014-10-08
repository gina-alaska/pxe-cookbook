#
# Cookbook Name:: kickstart
# Recipe:: default
#
# Copyright (C) 2014 UAF-GINA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.set['apache2']['default_site_enabled'] = false
include_recipe 'apache2'


directory node['kickstart']['web_root'] do
  action :create
  recursive true
end

node['kickstart']['files'].each do |file|
  cookbook_file "#{node['kickstart']['web_root']}/#{file}"
end

web_app 'kickstart' do
  template 'kickstart.conf.erb'
  cookbook 'kickstart'
  docroot node['kickstart']['web_root']
  server_name 'kickstart.sandy'
  directory_options ['Indexes']
end
