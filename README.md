Exploit mitigation patch for Hashicorp vagrant-vmware-fusion 4.0.24
===================================================================

During recent months I have published two CVEs documenting root privilege
escalation vulnerabilities in the Hashicorp vagrant-vmware-fusion plugin.

Version 4.0.24 is now released which addresses those bugs, but it still
depends on an suid root binary being present in order for vagrant to
communicate with VMWare.

The first time vagrant is invoked it will invoke osascript which opens a
dialog prompting the user for their password in order to elevate itself to
admin privileges.  It then uses the elevated privilege to chmod +s a sudo
wrapper script at a path similar to:

````
~/.vagrant.d/gems/2.3.4/gems/vagrant-vmware-fusion-4.0.24/bin/vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64
````

This binary then remains suid root and is used whenever vagrant needs to
elevate privileges in order to communicate with VMWare.

I decided to investigate whether I could mitigate any potential other
privilege escalation vectors by patching out the requirement for this suid
binary to always be present on the system.

This patch installs a simple bash wrapper script which ensures that every
time vagrant is run, the suid binary has its suid bit removed afterwards.

Neither this patch nor it's developer are in any way associated with
Hashicorp.

Use at your own risk!


Install
-------

````
$ ./vagrant_vmware_privesc_4.0.24_patch.sh -i
````


Uninstall
---------
````
$ ./vagrant_vmware_privesc_4.0.24_patch.sh -u
````


