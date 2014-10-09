include_recipe "tftp::server"
include_recipe "pxe::common"
package 'syslinux'


begin
  pxebag = data_bag('pxe')
  defaults = data_bag_item('pxe', 'default').merge(node['pxe']['defaults'])
rescue
  log "No 'pxe' data bag found" do
    level :warn
  end
end

pxebag.each do |id|
  image_dir = "#{node['tftp']['directory']}/#{id}"
  image = defaults.merge(data_bag_item('pxe', id)).merge(node['pxe']['defaults'])

  platform = image['platform']
  arch = image['arch']
  version = image['version']


  if image['root']
    root_crypted_password = image['root']['crypted_password']
  end

  directory image_dir do
    mode 0755
  end

  remote_file "#{node['pxe']['dir']}/isos/#{platform}-#{version}-#{arch}-NetInstall.iso" do
    source image['netboot_url']
    action :create_if_missing
  end

  directory "#{node['tftp']['directory']}/pxe-#{platform}-#{version}-#{arch}.0" do
    action :create
    recursive true
  end

  mount "#{node['tftp']['directory']}/pxe-#{platform}-#{version}-#{arch}.0" do
    device "#{node['pxe']['dir']}/isos/#{platform}-#{version}-#{arch}-NetInstall.iso"
    options "loop"
    action [:enable, :mount]
  end

  ruby_block 'copy pxelinux.0' do
    block do
      ::FileUtils.cp("/usr/share/syslinux/pxelinux.0", "#{node['tftp']['directory']}/#{id}/pxelinux.0")
    end
    not_if { ::File.exists?("#{node['tftp']['directory']}/#{id}/pxelinux.0") }
  end

  if image['addresses']
    image['addresses'].keys.each do |mac_address|
      mac = mac_address.gsub(/:/, '-')
      mac.downcase!

      template "#{node['tftp']['directory']}/pxelinux.cfg/01-#{mac}" do
        source 'pxelinux.cfg.erb'
        mode 0644
        variables(
          images: image
        )
      end


    end
  end
  template "#{node['pxe']['dir']}/kickstart/#{image['id']}-kickstart.cfg" do
    source "#{platform}-#{version}-kickstart.conf.erb"
    mode 0644
    variables(
      :id => id,
      :boot_volume_size => image['boot_volume_size'] || '1GB',
      :packages => image['packages'] || '',
      :root_crypted_password => image['root_crypted_password'],
      # :halt => image['halt'] || false,
      :bootstrap => image['chef'] || true,
      :root_disks => Array(image['root_disks']),
      :packages => Array(image['packages'])
      )
  end
end

link "#{node['tftp']['directory']}/pxelinux.0" do
  to 'default/pxelinux.0'
end

images = search(:pxe, '*:*' )
images = images.each do |image|
  image['platform'] ||= 'centos'
  image['version'] ||= '7.0'
  image['arch'] ||= 'x86_64'
  image['hostname'] ||= 'unknown'
  image['kickstart'] ||= "#{image['id']}-kickstart.cfg"
end


template "#{node['tftp']['directory']}/pxelinux.cfg/default" do
  source 'pxelinux.cfg.erb'
  variables(
    images: images
  )
end

include_recipe 'pxe::installers'
include_recipe 'pxe::bootstrap_template'
