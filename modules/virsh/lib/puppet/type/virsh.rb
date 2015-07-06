require 'puppet/parameter/boolean'
require 'fileutils'

Puppet::Type.newtype(:virsh) do
	ensurable

	newparam(:name, :namevar => true) do
	end

	newparam(:virttype) do
	    desc 'The pool type.'
		validate do |value|
			if value =~  /vnetwork/
				resource[:provider] = :vnetwork
			else
				resource[:provider] = :vhost
			end
		end
	 end

	newparam(:cdrom) do
		validate  do |value|
			fail ("cdrom path ")   unless value =~ /^\//
		end
	end

	newparam(:force) do
		defaultto false
		newvalues(:true, :false)
	end


	newparam(:vncport) do
		newvalues(/\d+/)
	end

	newparam(:diskformat) do
		defaultto :raw
		newvalues(:raw, :qcow2)
	end

	newparam(:disksize) do
		newvalues(/\d+/)
	end

	newproperty(:vname) do
	end

	newproperty(:vnettype) do
		defaultto :bridge
		newvalues(:network, :bridge)
	end

	newproperty(:memory) do
		munge do |value|
			if value =~ /(\d+)([g|G|m|M])?/
				value = $1
			else
				value = 1024
			end
				value.to_s
		end
	end

	newproperty(:vcpus) do
		newvalues(/\d+/)
	end

	newproperty(:diskpath) do
		validate  do |value|
			fail ("cdrom path ")   unless value =~ /^\//
		end
	end


end
