## TABLE OF CONTENTS
* NOTES
* SET UP BACULA ENVIRONMENT
* INSTALL BACULA
* CONFIGURE **CLIENT'S** BACULA-FD
* CONFIGURE **CLIENT'S** **bacula-fd.conf**
* PREPARE THE BACULA **SERVER**
* TROUBLESHOOTING
* EXAMPLE OUTPUTS


#
## Notes
* If you already installed an older version of Bacula, be sure to uninstall it; there can only be one instance of Bacula on a client. 
  * `yum remove bacula-client`
* This process has been tested on the following systems:
  * CentOS 7.3, 7.4
  * Red Hat 7.3, 7.4
* The commands are listed with the assumption that you are signed in as *root*. If that is not possible, try using `sudo` before each command.
* As a prerequisite, I recommend generating a list of files and directories (**FileSets**, in Bacula terminology) you would like to backup. Verify that the size of all your files is acceptable. Doing this ahead of time will make the install process smoother in the long run. 
#
## SET UP BASIC ENVIRONMENT
#### FQDN:
If your client doesn't already have a Fully Qualified Domain Name (FQDN), assign it one. I use client.example.local in this tutorial. 

#### Install Dependencies:
##### Notes on the `yum` command below: 
* **lzip-devel** also installs **libzip**. As of Bacula 9.0.2, you shouldn't need to install it anymore, but it might not hurt to do so anyway.  
* If installing Bacula on Red Hat client, try to just install **libzip**
* **policycoreutils-python** is needed for `semanage` commands
* Feel free to substitue `vim` with your editor of choice

`yum install -y wget vim gcc gcc-c++ libacl-devel lzo-devel libzip-devel policycoreutils-python`

#### Check System Time and Sync if Incorrect:
`date -R`

`ntpdate -u 0.us.pool.ntp.org`

#### Configure Firewall
```bash
firewall-cmd --permanent --zone=public --add-port=9101-9103/tcp
firewall-cmd --reload
firewall-cmd --list-ports
```

#### Make directory where the Bacula Server can restore files:
`mkdir -p /bacula/restore`
#
## INSTALL BACULA

#### Install Bacula binarires
* Note: The below `wget` command will download the Bacula files in `/tmp`. Once Bacula is configured, however, the binaries will be in `/opt/bacula`.

`wget -O- https://sourceforge.net/projects/bacula/files/bacula/9.0.3/bacula-9.0.3.tar.gz/download | tar -xzvf - -C /tmp` 

#### Create a configuration script

`cd /tmp/bacula-9.0.3`
`vim setup.sh`
```
#!/bin/bash
    CFLAGS="-g -Wall" \
      ./configure \
        --enable-client-only \
        --enable-smartalloc \
```

#### Execute configuration script:
```bash
chmod +x setup.sh
./setup.sh
```

* Debug errors. An example of the output you might see is listed at the bottom section of this file.
* Closely review your configuration before moving on to make sure you are OK with the settings.

### Run `make` commands to install Bacula
```bash 
make
```

* Debug any errors. An example of the output you might see is shown at the bottom of this tutorial. 
	* Running `makedist clean` can sometimes be an easy fix for certain errors.
```bash
make install
make install-autostart-fd
```
* This creates symlinks to start the Bacula File-Daemon (FD) on boot
#
## CONFIGURE **CLIENT'S** BACULA-FD

#### If no errors, start the daemon and confirm it's running
`service bacula-fd start`

`service bacula-fd status`

#### Reboot and confirm that the FD starts on boot. 
`systemctl reboot`

##### If not, use systemctl command and reboot again to confirm:
```bash 
systemctl enable bacula-fd.service
systemctl reboot
```

#### Configure SELinux to allow director to write to /bacula director.
* This setp is required in order for the Bacula Director to restore files in `/bacula/restore`

```bash
chcon system_u:object_r:bacula_store_t:s0 /bacula
semanage fcontext -a -t bacula_store_t "/bacula/restore(/.*)?"
restorecon -R -v /bacula/restore/
```
#### Copy password from bacula-fd.conf
* Keep this password handy - you will need when configuring the **Server** to connect with your new **Client**. 
#
## CONFIGURE **CLIENT'S** **bacula-fd.conf**
`vim /opt/etc/bacula/bacula-fd.conf`
* *Important*: Change `Director { [..] Name =` to FQDN of client for the Director and Tray Monitor
* Note: FQDN does not necessarily equate to the server's hostname. It seems like Bacula places the hostname there by default when installing. Not updating the field to reflect the FQDN might lead to connection errors (see **Troubleshooting** section below for more information).

```bash
Director {
  Name = server.example.local-dir
  Password = "A"
}
Messages {
  Name = Standard
  director = server.example.local-dir = all, !skipped, !restored
}
```
* Change director name to `hostname + -dir` so logs can be sent to Server
#
## PREPARE THE BACULA **SERVER**
* Those are all the steps that you should need to take on the new **Client**. There are a number of **Server** config changes that will be required, however. An overview of those changes are listed in this file, but you should refer to the **ADD A CLIENT** section in: [bacula-install-server.md] (link) for step-by-step instructions.

### ON BACULA **SERVER** - UPDATE THE *filesets.conf* FILE:
* This step is only needed if you would like to create a custom FileSet for your client. Skip this step if you are OK with using Bacula's generic FileSets.

`vim /opt/bacula/etc/conf.d/clients.conf`

### ON BACULA **SERVER** - UPDATE THE *clients.conf* FILE:
`vim /opt/bacula/etc/conf.d/clients.conf`

### ON BACULA **SERVER** - UPDATE the *pools.conf*
`vim /opt/bacula/etc/conf.d/pools.conf`

### EDIT **SERVER'S** *bacula-fd.conf* FILE
`vim /opt/bacula/etc/bacula-fd.conf`

### After troubleshooting any issues, continue following instructions listed in `bacula-install-server.md`.

#
## TROUBLESHOOTING
#### Problem 1: `make` error:
```
==>Entering directory /usr/src/bacula-9.0.1/src/filed
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/filed'
Compiling filed.c
Compiling authenticate.c
Compiling backup.c
backup.c: In function ‘bool setup_compression(bctx_t&)’:
backup.c:1080:9: error: ‘struct bctx_t’ has no member named ‘max_compress_len’
    bctx.max_compress_len = 0;
         ^
backup.c:1022:9: warning: unused variable ‘jcr’ [-Wunused-variable]
    JCR *jcr = bctx.jcr;
         ^
make[1]: *** [backup.o] Error 1
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/filed'
```
* **Potential Solution 1**: Make sure you installed all needed packages. See above for list. 


#
## EXAMPLE OUTPUTS
`./setup.sh`
```bash
Configuration on Sat Aug  5 00:57:53 CDT 2017:

   Host:		     x86_64-pc-linux-gnu -- redhat Enterprise release
   Bacula version:	     Bacula 9.0.1 (12 July 2017)
   Source code location:     .
   Install binaries:	     /sbin
   Install libraries:	     /usr/lib64
   Install config files:     /etc/bacula
   Scripts directory:	     /etc/bacula
   Archive directory:	     /tmp
   Working directory:	     /opt/bacula/working
   PID directory:	     /var/run
   Subsys directory:	     /var/lock/subsys
   Man directory:	     ${datarootdir}/man
   Data directory:	     /usr/share
   Plugin directory:	     /usr/lib64
   C Compiler:		     gcc 4.8.5
   C++ Compiler:	     /usr/bin/g++ 4.8.5
   Compiler flags:	      -g -Wall -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti
   Linker flags:	      
   Libraries:		     -lpthread -ldl -ldl 
   Statically Linked Tools:  no
   Statically Linked FD:     no
   Statically Linked SD:     no
   Statically Linked DIR:    no
   Statically Linked CONS:   no
   Database backends:	     None
   Database port:	      
   Database name:	     bacula
   Database user:	     bacula
   Database SSL options:     

   Job Output Email:	     root@localhost
   Traceback Email:	     root@localhost
   SMTP Host Address:	     localhost

   Director Port:	     9101
   File daemon Port:	     9102
   Storage daemon Port:      9103

   Director User:	     
   Director Group:	     
   Storage Daemon User:      
   Storage DaemonGroup:      
   File Daemon User:	     
   File Daemon Group:	     

   Large file support:	     yes
   Bacula conio support:     yes -ltinfo
   readline support:	     no 
   TCP Wrappers support:     no 
   TLS support: 	     no
   Encryption support:	     no
   ZLIB support:	     no
   LZO support: 	     no
   enable-smartalloc:	     yes
   enable-lockmgr:	     no
   bat support: 	     no
   client-only: 	     yes
   build-dird:		     yes
   build-stored:	     yes
   Plugin support:	     yes
   AFS support: 	     no
   ACL support: 	     yes
   XATTR support:	     yes
   systemd support:	     no 
   Batch insert enabled:     None
```

`make` 
* Note: This should be run after `./setup.sh`

```
[root@client.example-9.0.1]# make
==>Entering directory /usr/src/bacula-9.0.1/src
make[1]: Entering directory `/usr/src/bacula-9.0.1/src'
make[1]: Nothing to be done for `all'.
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src'
==>Entering directory /usr/src/bacula-9.0.1/scripts
make[1]: Entering directory `/usr/src/bacula-9.0.1/scripts'
make[1]: Nothing to be done for `all'.
make[1]: Leaving directory `/usr/src/bacula-9.0.1/scripts'
==>Entering directory /usr/src/bacula-9.0.1/src/lib
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/lib'
Compiling attr.c
Compiling base64.c
Compiling berrno.c
Compiling bsys.c
Compiling binflate.c
Compiling bget_msg.c
Compiling bnet.c
Compiling bnet_server.c
Compiling bsock.c
Compiling bpipe.c
Compiling bsnprintf.c
Compiling btime.c
Compiling cram-md5.c
Compiling crc32.c
Compiling crypto.c
Compiling daemon.c
Compiling edit.c
Compiling fnmatch.c
Compiling guid_to_name.c
Compiling hmac.c
Compiling jcr.c
Compiling lex.c
Compiling lz4.c
Compiling alist.c
Compiling dlist.c
Compiling md5.c
Compiling message.c
Compiling mem_pool.c
Compiling openssl.c
Compiling plugins.c
Compiling priv.c
Compiling queue.c
Compiling bregex.c
Compiling runscript.c
Compiling rwlock.c
Compiling scan.c
Compiling sellist.c
Compiling serial.c
Compiling sha1.c
Compiling sha2.c
Compiling signal.c
Compiling smartall.c
Compiling rblist.c
Compiling tls.c
Compiling tree.c
Compiling util.c
Compiling var.c
Compiling watchdog.c
Compiling workq.c
Compiling btimers.c
Compiling worker.c
Compiling flist.c
Compiling address_conf.c
Compiling breg.c
Compiling htable.c
Compiling lockmgr.c
Compiling devlock.c
Compiling output.c
Compiling bwlimit.c
Making libbac.la ...
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++    -o libbac.la attr.lo base64.lo berrno.lo bsys.lo binflate.lo bget_msg.lo bnet.lo bnet_server.lo bsock.lo bpipe.lo bsnprintf.lo btime.lo cram-md5.lo crc32.lo crypto.lo daemon.lo edit.lo fnmatch.lo guid_to_name.lo hmac.lo jcr.lo lex.lo lz4.lo alist.lo dlist.lo md5.lo message.lo mem_pool.lo openssl.lo plugins.lo priv.lo queue.lo bregex.lo runscript.lo rwlock.lo scan.lo sellist.lo serial.lo sha1.lo sha2.lo signal.lo smartall.lo rblist.lo tls.lo tree.lo util.lo var.lo watchdog.lo workq.lo btimers.lo worker.lo flist.lo address_conf.lo breg.lo htable.lo lockmgr.lo devlock.lo output.lo bwlimit.lo  -export-dynamic -rpath /usr/lib64 -release 9.0.1   -lz  -lpthread -ldl -ldl  -ldl 
Compiling ini.c
Compiling parse_conf.c
Compiling res.c
Compiling bjson.c
Making libbaccfg.la ...
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++    -o libbaccfg.la ini.lo parse_conf.lo res.lo bjson.lo  -export-dynamic -rpath /usr/lib64 -release 9.0.1  -lpthread -ldl -ldl 
==== Make of lib is good ====
 
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/lib'
==>Entering directory /usr/src/bacula-9.0.1/src/findlib
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/findlib'
Compiling find.c
Compiling match.c
Compiling find_one.c
Compiling attribs.c
Compiling create_file.c
Compiling bfile.c
Compiling drivetype.c
Compiling enable_priv.c
Compiling fstype.c
Compiling mkpath.c
Compiling savecwd.c
Compiling win32filter.c
Making libbacfind.la ...
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++    -o libbacfind.la find.lo match.lo find_one.lo attribs.lo create_file.lo bfile.lo drivetype.lo enable_priv.lo fstype.lo mkpath.lo savecwd.lo win32filter.lo -export-dynamic -rpath /usr/lib64 -release 9.0.1
==== Make of findlib is good ====
 
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/findlib'
==>Entering directory /usr/src/bacula-9.0.1/src/filed
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/filed'
Compiling filed.c
Compiling authenticate.c
Compiling backup.c
Compiling crypto.c
Compiling estimate.c
Compiling fd_plugins.c
Compiling accurate.c
Compiling filed_conf.c
Compiling heartbeat.c
Compiling hello.c
Compiling job.c
Compiling fd_snapshot.c
Compiling restore.c
Compiling status.c
Compiling verify.c
Compiling verify_vol.c
Compiling xacl.c
Compiling xacl_linux.c
Compiling xacl_osx.c
Compiling xacl_solaris.c
Compiling xacl_freebsd.c
Linking bacula-fd ...
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++   -L../lib -L../findlib -o bacula-fd filed.o authenticate.o backup.o crypto.o estimate.o fd_plugins.o accurate.o filed_conf.o heartbeat.o hello.o job.o fd_snapshot.o restore.o status.o verify.o verify_vol.o xacl.o xacl_linux.o xacl_osx.o xacl_solaris.o xacl_freebsd.o \
  -lacl 		   -lz -lbacfind -lbaccfg -lbac -lm -lpthread -ldl -ldl  \
        
Compiling bfdjson.c
Linking bfdjson ...
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++   -L../lib -L../findlib -o bfdjson bfdjson.o filed_conf.o \
   -lacl 		   -lz -lbacfind -lbaccfg -lbac -lm -lpthread -ldl -ldl  \
        
==== Make of filed is good ====
 
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/filed'
==>Entering directory /usr/src/bacula-9.0.1/src/console
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/console'
Compiling console.c
Compiling console_conf.c
Compiling authenticate.c
Compiling conio.c
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++   -L../lib -L../cats -o bconsole console.o console_conf.o authenticate.o conio.o \
       -ltinfo -lbaccfg -lbac -lm -lpthread -ldl -ldl   \
      
Compiling bbconsjson.c
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++   -L../lib -L../cats -o bbconsjson bbconsjson.o console_conf.o \
       -ltinfo -lbaccfg -lbac -lm -lpthread -ldl -ldl   \
      
==== Make of console is good ====
 
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/console'
==>Entering directory /usr/src/bacula-9.0.1/src/plugins/fd
make[1]: Entering directory `/usr/src/bacula-9.0.1/src/plugins/fd'
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=compile /usr/bin/g++   -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -g -Wall -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -I../.. -I../../filed -c bpipe-fd.c
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++  -shared bpipe-fd.lo -o bpipe-fd.la -rpath /usr/lib64 -module -export-dynamic -avoid-version 
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=compile /usr/bin/g++   -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -g -Wall -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -I../.. -I../../filed -c test-plugin-fd.c
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++  -shared test-plugin-fd.lo -o test-plugin-fd.la -rpath /usr/lib64 -module -export-dynamic -avoid-version 
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=compile /usr/bin/g++   -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -g -Wall -x c++ -fno-strict-aliasing -fno-exceptions -fno-rtti  -I../.. -I../../filed -c test-deltaseq-fd.c
/usr/src/bacula-9.0.1/libtool --silent --tag=CXX --mode=link /usr/bin/g++  -shared test-deltaseq-fd.lo -o test-deltaseq-fd.la -rpath /usr/lib64 -module -export-dynamic -avoid-version 
make[1]: Leaving directory `/usr/src/bacula-9.0.1/src/plugins/fd'
==>Entering directory /usr/src/bacula-9.0.1/manpages
make[1]: Entering directory `/usr/src/bacula-9.0.1/manpages'
make[1]: Nothing to be done for `all'.
make[1]: Leaving directory `/usr/src/bacula-9.0.1/manpages'
```

`make install`
* Note: This should be run after `make`
```
[root@client.example bacula-9.0.3]# make install
./autoconf/mkinstalldirs /sbin
./autoconf/mkinstalldirs /etc/bacula
mkdir -p -- /etc/bacula
chmod 770 /etc/bacula
if test "x" != "x" ; then \
   chown  /etc/bacula; \
fi
if test "x" != "x" ; then \
   chgrp  /etc/bacula; \
fi
./autoconf/mkinstalldirs /etc/bacula
./autoconf/mkinstalldirs /usr/share/doc/bacula
mkdir -p -- /usr/share/doc/bacula
./autoconf/mkinstalldirs /tmp
./autoconf/mkinstalldirs 
./autoconf/mkinstalldirs /opt/bacula/log
mkdir -p -- /opt/bacula/log
if test ! -d /opt/bacula/working ; then \
   ./autoconf/mkinstalldirs /opt/bacula/working; \
   chmod 770 /opt/bacula/working; \
fi
mkdir -p -- /opt/bacula/working
if test "x" != "x" ; then \
   chown  /opt/bacula/working; \
   chown  /opt/bacula/log; \
fi
if test "x" != "x" ; then \
   chgrp  /opt/bacula/working; \
   chgrp  /opt/bacula/log; \
fi
make[1]: Entering directory `/tmp/bacula-9.0.3/src'
make[1]: Nothing to be done for `install'.
make[1]: Leaving directory `/tmp/bacula-9.0.3/src'
make[1]: Entering directory `/tmp/bacula-9.0.3/scripts'
../autoconf/mkinstalldirs /etc/bacula
../autoconf/mkinstalldirs /sbin
../autoconf/mkinstalldirs /etc/bacula
../autoconf/mkinstalldirs /usr/share/man
/bin/install -c -m 0750 bconsole /etc/bacula/bconsole
/bin/install -c -m 0750 bacula /etc/bacula/bacula
/bin/install -c -m 0750 bacula_config /etc/bacula/bacula_config
/bin/install -c -m 0750 bacula /sbin/bacula
/bin/install -c -m 0750 tapealert /etc/bacula/tapealert
/bin/install -c -m 0750 bacula-ctl-dir /etc/bacula/bacula-ctl-dir
/bin/install -c -m 0750 bacula-ctl-fd /etc/bacula/bacula-ctl-fd
/bin/install -c -m 0750 bacula-ctl-sd /etc/bacula/bacula-ctl-sd
/bin/install -c -m 0750 mtx-changer /etc/bacula/mtx-changer
/bin/install -c -m 0750 disk-changer /etc/bacula/disk-changer
/bin/install -c -m 644   btraceback.gdb /etc/bacula/btraceback.gdb
/bin/install -c -m 644   btraceback.dbx /etc/bacula/btraceback.dbx
/bin/install -c -m 644   btraceback.mdb /etc/bacula/btraceback.mdb
/bin/install -c -m 0750 baculabackupreport /etc/bacula/baculabackupreport
/bin/install -c -m 0750 bacula-tray-monitor.desktop /etc/bacula/bacula-tray-monitor.desktop
chmod 0644 /etc/bacula/btraceback.gdb \
	   /etc/bacula/btraceback.dbx \
	   /etc/bacula/btraceback.mdb
/bin/install -c -m 0750 btraceback /sbin/btraceback
make[1]: Leaving directory `/tmp/bacula-9.0.3/scripts'
make[1]: Entering directory `/tmp/bacula-9.0.3/src/lib'
==== Make of lib is good ====
 
/tmp/bacula-9.0.3/autoconf/mkinstalldirs /usr/lib64
/bin/rm -f /usr/lib64/libbac-*.so /usr/lib64/libbac.la
/bin/rm -f /usr/lib64/libbaccfg-*.so /usr/lib64/libbaccfg.la
/bin/rm -f /usr/lib64/libbacpy-*.so /usr/lib64/libbacpy.la
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --finish --mode=install /bin/install -c -m 755 libbac.la /usr/lib64
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --finish --mode=install /bin/install -c -m 755 libbaccfg.la /usr/lib64
make[1]: Leaving directory `/tmp/bacula-9.0.3/src/lib'
make[1]: Entering directory `/tmp/bacula-9.0.3/src/findlib'
==== Make of findlib is good ====
 
/tmp/bacula-9.0.3/autoconf/mkinstalldirs /usr/lib64
/bin/rm -f /usr/lib64/libbacfind-*.so /usr/lib64/libbacfind.la
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --finish --mode=install /bin/install -c -m 755 libbacfind.la /usr/lib64
make[1]: Leaving directory `/tmp/bacula-9.0.3/src/findlib'
make[1]: Entering directory `/tmp/bacula-9.0.3/src/filed'
==== Make of filed is good ====
 
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 0750 bacula-fd /sbin/bacula-fd
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 0750 bfdjson /sbin/bfdjson
/bin/install -c -m 660 bacula-fd.conf /etc/bacula/bacula-fd.conf
make[1]: Leaving directory `/tmp/bacula-9.0.3/src/filed'
make[1]: Entering directory `/tmp/bacula-9.0.3/src/console'
==== Make of console is good ====
 
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 755 bconsole /sbin/bconsole
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 0750 bbconsjson /sbin/bbconsjson
/bin/install -c -m 660 bconsole.conf /etc/bacula/bconsole.conf
if test -f static-bconsole; then \
   /tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 0750 static-bconsole /sbin/static-bconsole; \
fi
make[1]: Leaving directory `/tmp/bacula-9.0.3/src/console'
make[1]: Entering directory `/tmp/bacula-9.0.3/src/plugins/fd'
/tmp/bacula-9.0.3/autoconf/mkinstalldirs /usr/lib64
/tmp/bacula-9.0.3/libtool --silent --tag=CXX --mode=install /bin/install -c -m 0750 bpipe-fd.la /usr/lib64
/bin/rm -f /usr/lib64/bpipe-fd.la
make[1]: Leaving directory `/tmp/bacula-9.0.3/src/plugins/fd'
make[1]: Entering directory `/tmp/bacula-9.0.3/manpages'
/tmp/bacula-9.0.3/autoconf/mkinstalldirs //usr/share/man/man8
for I in bacula.8 bacula-dir.8 bacula-fd.8 bacula-sd.8 bconsole.8 bcopy.8 bextract.8 bls.8 bscan.8 btape.8 btraceback.8 dbcheck.8 bwild.8 bregex.8; \
  do (/bin/rm -f $I.gz; gzip -c $I >$I.gz; \
     /bin/install -c -m 644 $I.gz /usr/share/man/man8/$I.gz; \
     rm -f $I.gz); \
done
/tmp/bacula-9.0.3/autoconf/mkinstalldirs //usr/share/man/man1
for I in bsmtp.1 bat.1; \
  do (/bin/rm -f $I.gz; gzip -c $I >$I.gz; \
     /bin/install -c -m 644 $I.gz /usr/share/man/man1/$I.gz; \
     rm -f $I.gz); \
done
make[1]: Leaving directory `/tmp/bacula-9.0.3/manpages'
```

`make install-autostart-fd`
* Note: This should be run after `make install`
```
[root@client.example bacula-9.0.3]# make install-autostart-fd
(cd platforms && make DESTDIR= install-autostart-fd || exit 1)
make[1]: Entering directory `/tmp/bacula-9.0.3/platforms'
make[2]: Entering directory `/tmp/bacula-9.0.3/platforms/redhat'
# set symlinks for script at startup and shutdown
make[2]: Leaving directory `/tmp/bacula-9.0.3/platforms/redhat'
make[1]: Leaving directory `/tmp/bacula-9.0.3/platforms'
```


