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

It turns out this is possible and today I am releasing a mitigation patch
which adds an intermediate binary in the execution chain between vagrant
and the sudo wrapper binary.

When vagrant is invoked it will chmod +s and then invoke this new binary
rather than the actual sudo wrapper, which is renamed to:

````
vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64.bin
````

When this binary is executed it detects whether it's running with elevated
privileges (ie is suid root).  If it is then it calls chmod -s on itself
and then passes the parameters on to the real sudo wrapper binary.  If it's
called *without* root privileges then it invokes osascript to chmod +s
itself, which is authenticated by the user with another password dialog.
Once this is done it then re-invokes itself in order to elevate to root,
then since it is now running with elevated privileges it calls chmod -s on
itself and passes the arguments on to the real sudo wrapper.

The net result of this is that whenever vagrant needs elevated privileges
the user will get a password prompt to confirm it.  After each privileged
execution the suid bit is removed from the intermediate wrapper binary so
as not to leave the suid binary on the system.  This is a slightly less
great user experience as a simple "vagrant up" will result in two password
prompts but I prefer this tradeoff rather than having the suid wrapper
lying around suid root on the system.


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


