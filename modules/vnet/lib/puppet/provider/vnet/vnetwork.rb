Puppet::Type.type(:vnet).provide(:vnetwork) do
	commands :vshow 	=> '/usr/bin/virsh'
	commands :brctl 	=> '/usr/sbin/brctl'

	def self.instances
		network_card	= vshow('iface-list')
		@vline = Hash.new

		network_card.split(/\n/)[2..-1].map do |value|
			line		= value.split(/\s+/)
			bridges		= brctl('show',line[0])
			bridges.split(/\n/)[1..-1].map do |bridge|
					next	if bridge =~ /^(lo)/
				bridge_line = bridge.strip.split(/\s+/)	
				if bridge_line.size > 1 and bridge_line.size < 5
					@key			= bridge_line[0]	
					@phycard		= bridge_line[3]
					@vline[@key] 	= Array.new
					@vline[@key].push(@phycard)
				elsif bridge_line.length  == 1
					@vline[@key].push(bridge_line[0])
				end
			end
		end

		@vline.keys.collect do |value|
			new( :name		=> value,
				 :phycard	=> @vline[value],
				 :ensure	=> :present
			)
		end
	end

	def create
		vshow('iface-bridge',resource[:phycard],resource[:name])
		@property_hash[:ensure] = :present
	end



	def destroy
		vshow('iface-unbridge',resource[:name])	
		@property_hash[:ensure] = :absent

	end

	def exists?
		a_args = ['phycard']
		a_args.each do  |value|
			break 	if		@property_hash[value.to_sym].to_s == '' or resource[value].to_s == ''
			unless	@property_hash[value.to_sym].to_s.include?(resource[value].to_s)
					return false
			end
		end
		@property_hash[:ensure]  == :present
	end

	def self.prefetch(resources)
		bridges = instances
		resources.keys.each do |name|
			if provider = bridges.find{|bridge| bridge.name == name}
				resources[name].provider = provider
			end
		end
	end

	def phycard
		@property_hash[:phycard] || false
	end

	def phycard=(phycard)
		@property_hash[:phycard].push(phycard)
	end
end
