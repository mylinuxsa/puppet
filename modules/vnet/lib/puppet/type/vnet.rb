Puppet::Type.newtype(:vnet) do
	ensurable

	newparam(:name, :namevar => true) do
	end
	
	newparam(:virttype) do
	    desc 'The pool type.'
		validate do |value|
	end
	newproperty(:phycard) do
	end

end
