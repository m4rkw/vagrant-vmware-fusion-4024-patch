#!/bin/bash
echo
echo "Exploit mitigation patch for vagrant-vmware-fusion 4.0.24"
echo "by m4rkw"
echo
echo "When installed vagrant will prompt multiple times for credentials when"
echo "it needs them, but there will be no potentially vulnerable suid root"
echo "binary lying around on the system."
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

plugin_dir=`find ~/.vagrant.d -type d -name vagrant-vmware-fusion-4.0.24`

if [ $plugin_dir == "" ] ; then
  echo "Plugin directory not found."
  exit 1
fi

wrapper="$plugin_dir/bin/vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64"

if [ ! -e "$wrapper" ] ; then
  echo "wrapper binary not found at: $wrapper"
  exit 1
fi

if [ "$1" == "-i" ] ; then
  if [ ! -e "$wrapper.bin" ] ; then
    cp $wrapper $wrapper.bin
  fi

  rm -f $wrapper

  cat > /tmp/vagrant_vmware_4.0.24_patch.c <<EOF
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libproc.h>
#include <unistd.h>

int main (int ac, char *av[])
{
    int i, ret;
    pid_t pid;
    char path[PROC_PIDPATHINFO_MAXSIZE];
    char *p[ac+1];
    char buffer[2048];

    pid = getpid();
    ret = proc_pidpath (pid, path, sizeof(path));

    if ( ret <= 0 ) {
      fprintf(stderr, "%s\n", strerror(errno));
      return 1;
    }

    for (i = strlen(path)-1; i >= 0; i--) {
      if (path[i] == '/') {
        path[i] = 0;
        break;
      }
    }

    chdir(path);

    for (i=1; i<ac; i++) {
      p[i] = av[i];
    }

    p[ac] = NULL;

    setuid(0);

    if (seteuid(0) != 0) {
      system("/usr/bin/osascript -e \\"do shell script \\\\\"chown root:wheel ./vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64\nchmod 4755 ./vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64\\\\\" with administrator privileges\\"");

      p[0] = "vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64";
      execvp("./vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64", p);
    } else {
      snprintf((char *)&buffer, sizeof(buffer), "%s/vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64", path);
      chmod(buffer, 0755);

      p[0] = "vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64.bin";
      execvp("./vagrant_vmware_desktop_sudo_helper_wrapper_darwin_amd64.bin", p);
    }

    return 0;
}
EOF
  clang -o $wrapper /tmp/vagrant_vmware_4.0.24_patch.c

  if [ ! $? -eq 0 ] ; then
    echo "Compilation failed, check xcode and the commandline tools are installed."

    rm -f /tmp/vagrant_vmware_4.0.24_patch.c
    exit 1
  fi
  rm -f /tmp/vagrant_vmware_4.0.24_patch.c

  echo "Patch installed."
  echo
else
	if [ ! -e "$wrapper.bin" ] ; then
    echo "Patch doesn't seem to be installed."
    exit 1
  fi

  rm -f $wrapper
  cp "$wrapper.bin" $wrapper
  rm -f "$wrapper.bin"

  echo "Patch uninstalled"
  echo
fi
