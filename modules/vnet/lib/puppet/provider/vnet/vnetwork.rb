require 'fileutils'

Puppet::Type.type(:vnet).provide(:vnetwork) do
	commands :vshow 	=> '/usr/bin/virsh'
	commands :brctl 	=> '/usr/sbin/brctl'

	def self.instances
		bridges = brctl('show')
		@name
		@vline = {}
		bridges.split(/\n/)[1..-1].map do |bridge|
			line = bridge.strip.split(/\s+/)	
			if line.size > 1
				@name 		= line[0]	
				@vline[@name] = [] 
				@vline[@name].push(line[-1])
			elsif line.length  == 1
				@vline[@name].push(line[0])
			end
		end
		
		@vline.keys.collect do |key|
			new( :name		=> key,
				 :phycard	=> @vline[key],
				 :provider	=> self.name,
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
		@property_hash[:ensure]  == :present
	end

	def self.prefetch(resources)
		bridges = instances
		resources.keys.each do |name|
			if provider = bridges.find{|bridge| bridge.name == name}
				resources[name].provider = provider
			end
		end

		resources.each do |k,v|
			puts "#{k}=>#{v}\n"
		end

	end

	def phycard
		@property_hash[:phy] || false
	end

	def phycard=(phycard)
		@property_hash[:phy] || false
	end
end
