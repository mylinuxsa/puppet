class virsh::config {
	virsh { "redhat" :
		ensure		=> present,
		force		=> true,
		memory		=> 2048,
		virttype	=> 'vhost',
		vncport		=> 5903,
		vcpus		=> 2,
		diskpath	=> '/data/xuniji/redhat.img',
		disksize	=> 60,
		diskformat	=> 'qcow2',
		cdrom		=> '/data/xuniji/CentOS-6.4-x86_64-bin-DVD1.iso',
		vname		=> 'br1',
		vnettype	=> 'bridge',
		
	}
	virsh { "centos" :
		ensure		=> present,
		force		=> true,
		memory		=> 2048,
		virttype	=> 'vhost',
		vncport		=> 5902,
		vcpus		=> 2,
		diskpath	=> '/data/xuniji/centos.img',
		disksize	=> 60,
		diskformat	=> 'qcow2',
		cdrom		=> '/data/xuniji/CentOS-6.4-x86_64-bin-DVD1.iso',
		vname		=> 'br1',
		vnettype	=> 'bridge',
	}
	virsh { "windows" :
		ensure		=> present,
		force		=> true,
		memory		=> 1024,
		virttype	=> 'vhost',
		vncport		=> 5904,
		vcpus		=> 2,
		diskpath	=> '/data/xuniji/windows.img',
		disksize	=> 60,
		diskformat	=> 'qcow2',
		cdrom		=> '/data/xuniji/CentOS-6.4-x86_64-bin-DVD1.iso',
		vname		=> 'br1',
		vnettype	=> 'bridge',
	}
}
