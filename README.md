# puppet
puppet lib


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
}

class vnet::config {
	vnet { "br1" :
		ensure		=> present,
		virttype	=> 'vnetwork',
		phycard		=> 'eth1',
	}
}
