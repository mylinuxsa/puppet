# puppet
puppet lib




class vnet::config {
	vnet { "br1" :
		ensure		=> present,
		virttype	=> 'vnetwork',
		phycard		=> 'eth1',
	}
}
