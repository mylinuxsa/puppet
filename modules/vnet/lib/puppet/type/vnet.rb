require 'puppet/parameter/boolean'
require 'fileutils'

Puppet::Type.newtype(:vnet) do
	ensurable

	newparam(:name, :namevar => true) do
	end
	
	newparam(:virttype) do
	    desc 'The pool type.'
		validate do |value|
			if value =~  /vnetwork/
				resource[:provider] = :vnetwork
			else
				resource[:provider] = :vnetwork
			end
		end
	 end
	
	
	newproperty(:phycard) do
	end


end
