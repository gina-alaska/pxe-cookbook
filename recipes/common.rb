node.set['apache2']['default_site_enabled'] = false
include_recipe 'apache2'


[
  "#{node['pxe']['dir']}/isos",
  "#{node['pxe']['dir']}/kickstart/",
  "#{node['tftp']['directory']}/pxelinux.cfg"
].each do |dir|
  directory dir do
    recursive true
    mode 0755
  end
end

web_app 'pxe' do
  template 'pxe.conf.erb'
  cookbook 'pxe'
  docroot node['pxe']['dir']
  server_name node['ipaddress']
  server_alias node['pxe']['server_aliases'] if node['pxe']['server_aliases']
  directory_options ['Indexes','FollowSymLinks']
end
