require 'spec_helper'

describe 'kickstart::default' do
  let(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end


  # it 'disables the default site' do
  #
  # end

  it 'installs apache2' do
    expect(chef_run).to include_recipe('apache2')
  end

end
