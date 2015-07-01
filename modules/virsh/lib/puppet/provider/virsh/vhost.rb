Puppet::Type.type(:virsh).provide(:vhost) do
	commands :vshow 	=> '/usr/bin/virsh'
	commands :qemu_img 	=> '/usr/bin/qemu-img'
	commands :vinstall	=> '/usr/sbin/virt-install'

	def self.instances
		vms = vshow('-q','list','--all')
		vms.split(/\n/)[0..-1].map do |vm|
			line = vm.strip.split(/\s+/)	
			name 	= line[1]	
			status	= line[2] 

			blks = vshow('domblklist', name)
			blks.each do |blk|
				@diskpath = $1	if blk =~ /\s+(.*\.img)\s/
			end

			nets = vshow('domiflist',name)
			nets.each do |net|
				if net =~ /^.*\s+(network|bridge)\s+(.*?)\s+/
					@ntype = $1
					@nname = $2
				end
			end

			memnum = vshow('dommemstat', name)
			memnum.each do |mems|			
				if mems =~ /actual\s+(\d+)/
					@memory = $1.to_i  / 1024
				end
			end

			vcpunum = vshow('vcpucount',name)			
			vcpunum.each do |vcpu|
				@cpu = $1	if vcpu =~ /current\s+config\s+(\d+)/
			end

			vncnum  = vshow('vncdisplay', name)
			vncnum.split(/\n/).each do |vnc|
				@vncport = $1.to_i + 5900		if vnc =~ /:(\d+)/
			end


			new( :name		=> name,
				 :diskpath	=> @diskpath,
				 :vnettype  => @ntype,
				 :vnet		=> @nname,
				 :memory	=> @memory,
				 :vncport	=> @vncport,
				 :vcpus		=> @cpu,
				 :ensure	=> :present
			#	 :provider	=> self.name
			)
		end
	end

	def create

		disksize	= resource[:disksize] || 40
		if resource[:diskformat].to_s =~ /qcow2/
			qemu_img('create','-f',resource[:diskformat],resource[:diskpath],"#{disksize.to_s}G" )
		end
		name 		= '--name='  + resource[:name]
		memory		= '--ram='	 + resource[:memory]
		diskpath	= 'path=' 	 + resource[:diskpath] + ',size=' + disksize.to_s + ',format=' + resource[:diskformat].to_s + ',bus=virtio'
		vcpus		= '--vcpus=' + resource[:vcpus].to_s
		vnclisten	= %q(vnc,listen="0.0.0.0")
	
		if resource[:vncport]
			vnc	= vnclisten +	',port=' + resource[:vncport].to_s			
		end

		if resource[:cdrom]
			cdrom 	= '--cdrom=' + resource[:cdrom]
		else
			cdrom 	= '--boot=hd'
		end
		args 		= [name,memory,'--disk',diskpath,vcpus,cdrom,'--graphics',vnc]
		vinstall *args
		@property_hash[:ensure] = :present
	end



	def destroy

		shutdown(resource)
		undefine(resource)
		delete_hd(resource) 	if 	resource[:force]
		@property_hash[:ensure] = :absent

	end

	def exists?
		@property_hash[:ensure]  == :present
	end
	def self.prefetch(resources)
		vms = instances
		resources.keys.each do |name|
			if provider = vms.find{|vm| vm.name == name}
				resources[name].provider = provider
			end
		end
	end

	def memory
		@property_hash[:memory] || false
	end

	def memory=(memory)
		@property_hash[:memory] = ( memory.to_i * 1024 )
	end

	def vcpus
		@property_hash[:vcpus] || false
	end

	def vcpus=(vcpus)
		@property_hash[:vcpus] = vcpus
	end

	def diskpath
		@property_hash[:diskpath] || false
	end

	def diskpath=(diskpath)
		@property_hash[:diskpath] = diskpath
	end

	
	def shutdown(resource)
		vshow('destroy',resource[:name])
	end

	def undefine(resource)
		vshow('undefine',resource[:name])
	end

	def delete_hd(resource) 	
		blklist = vshow('-q','domblklist', resource[:name])
		blklist.split(/\n/)[0..-1].map do |blk|
			if blk =~ /^[hvs]d[a-z]\s+(.*)/
				disk = $1
				File.delete(disk)		unless disk =~ /\.iso$/
			end
		end
	end

end
