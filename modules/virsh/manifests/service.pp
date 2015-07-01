class virsh::service {
	service { "libvirtd" :
		ensure		=> running,
		enable		=> true,
		hasstatus	=> true,
		hasrestart	=> true,
		require		=> Class['virsh::install'],
	}
}
