#!/bin/bash
echo
echo "Exploit mitigation patch for vagrant-vmware-fusion 4.0.24"
echo "by m4rkw"
echo
echo "When installed the vulnerable binary will be stripped of it's suid flag"
echo "after vagrant is run."
echo
echo "For full details please see:"
echo "https://github.com/m4rkw/vagrant-vmware-fusion-4024-patch"
echo

usage() {
  echo "  install: $0 -i"
  echo "uninstall: $0 -u"
  echo
  exit
}

if [ "$1" != "-i" -a "$1" != "-u" ] ; then
  usage
fi

if [ "`whoami`" == "root" ] ; then
  echo "Don't run this as root."
  exit 1
fi

if [ "`uname`" != "Darwin" ] ; then
  echo "This only works on MacOS."
  exit 1
fi

if [ "`uname -a |sed 's/.* //'`" != "x86_64" ] ; then
  echo "Only 64bit platforms are supported."
  exit 1
fi

if [ "`which vagrant`" == "" ] ; then
  echo "vagrant not found."
  exit 1
fi

plugin=`vagrant plugin list |egrep '^vagrant-vmware-fusion'`

if [ "$plugin" == "" ] ; then
  echo "vagrant-vmware-fusion plugin not found."
  exit 1
fi

version=`echo "$plugin" |cut -d '(' -f2 |cut -d ')' -f1`

if [ "$version" != "4.0.24" ] ; then
  echo "This patch is for version 4.0.24 of vagrant-vmware-fusion, this system has $version."
  exit 1
fi

if [ "$1" == "-i" ] ; then
	if [ -e ~/bin/vagrant ] ; then
    echo "Patch already installed."
    exit 0
  fi

  if [ ! -e ~/bin ] ; then
    mkdir ~/bin
  fi

  vagrant_path=`which vagrant`

  cat >> ~/bin/vagrant <<EOF
#!/bin/bash
/usr/local/bin/vagrant \$@

vuln=`find ~/.vagrant.d -perm +4000 -name vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64`
if [ "\$vuln" != "" ] ; then
  cp \$vuln \$vuln.bak
  rm -f \$vuln
  mv \$vuln.bak \$vuln
  chmod 755 \$vuln
fi
EOF
  chmod 755 ~/bin/vagrant

  new_vagrant_path=`which vagrant`

  if [ "$new_vagrant_path" == "$vagrant_path" ] ; then
    echo "export PATH=~/bin:\$PATH" >> ~/.bash_profile
  fi

  echo "Patch installed."
else
  if [ -e ~/bin/vagrant ] ; then
    rm -f ~/bin/vagrant
    echo "Patch uninstalled."
  fi
fi
