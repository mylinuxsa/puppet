require 'fileutils'

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
				 :vname		=> @nname,
				 :memory	=> @memory,
				 :vncport	=> @vncport,
				 :vcpus		=> @cpu,
				 :ensure	=> :present
			)
		end
	end

	def create
		name 		= '--name='  + resource[:name].to_s
		memory		= '--ram='	 + resource[:memory].to_s
		vcpus		= '--vcpus=' + resource[:vcpus].to_s
		vnclisten	= %q(vnc,listen="0.0.0.0")

		disksize	= resource[:disksize] || 40
		create_hd(resource,disksize)	unless FileTest.exists?(resource[:diskpath])
		diskpath	= build_diskpath(resource,disksize)
		
		vnc	= vnclisten +	',port=' + resource[:vncport].to_s			if resource[:vncport]
		boot_args 	= boot(resource)
		
		network_args	= create_network(resource)		

		args 		= [name,memory,'--disk',diskpath,vcpus,boot_args,'--graphics',vnc,'--network',network_args]
		vinstall *args
		@property_hash[:ensure] = :present
	end



	def destroy
		delete_hd(resource) 	if 	resource[:force]
		shutdown(resource)
		undefine(resource)
		@property_hash[:ensure] = :absent

	end

	def exists?
		a_args = ['diskpath','memory','vncport','vcpus','vname','vnettype']	
		a_args.each do |value|
			break		if resource[value].to_s == '' or  @property_hash[value.to_sym].to_s == ''		

			unless @property_hash[value.to_sym].to_s  == resource[value].to_s
				@property_hash[:ensure] = :absent 
				shutdown(resource)
				undefine(resource)
				break
			end
		end
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

	def vname
		@property_hash[:vname] || false
	end

	def vname=(vname)
		@property_hash[:vname] = vname
	end
	
	def vnettype
		@property_hash[:vnettype] || false
	end

	def vnettype=(vnettype)
		@property_hash[:vnettype] = vnettype
	end

	def shutdown(resource)
		vshow('destroy',resource[:name])
	end

	def undefine(resource)
		vshow('undefine',resource[:name])
	end

	def boot(resource)
		if resource[:cdrom] 
			'--cdrom=' + resource[:cdrom] 
		else
			'--boot=hd' 
		end
	end
	

	def create_network(resource)
		network_args = '' 
		if resource[:vnettype]	 =~ /network/ 
			network_args = 'network=' + resource[:vname] +  ',model=virtio'
		else
			network_args = 'bridge=' + resource[:vname] +  ',model=virtio'
		end
		return network_args
	end
	
	def build_diskpath(resource,disksize)
		diskpath	= 'path=' 	 + resource[:diskpath] + ',size=' + disksize.to_s + ',format=' + resource[:diskformat].to_s + ',bus=virtio'
		return diskpath	
	end

	def create_hd(resource,disksize)
		qemu_img('create','-f',resource[:diskformat],resource[:diskpath],"#{disksize.to_s}G" )
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
