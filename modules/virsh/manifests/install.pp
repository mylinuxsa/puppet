class virsh::install {
	package { ['qemu-kvm','libvirt','python-virtinst'] :
		ensure	=> 'present',

	}
}
