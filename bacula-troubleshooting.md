bacula-troubleshooting.md

## TABLE OF CONTENTS

## TO-DO
* Format document
* Finish T.O.C


#
### BACULUM GUI TROUBLESHOOTING
#### Problem: Can't sign in via hostname:9095
* **Potential Cause 1**: You don't have all needed packages. Sounds obvious, but it is worth checking.
    * Potential Solution: 
    
        `yum install baculum-common baculum-web baculum-web-httpd && service httpd restart`
        
        * Then retry signing in: http://localhost:9095 or http://<FQDN>:9095
    
* **Potential Cause 2**: Apache's mod_rewrite module isn't loaded
    * Potential Solution: run `apachectl -M | sort` to see if `rewrite_module` is loaded. 
    * If not, edit the Apache configs to load the module. See [this article](https://devops.profitbricks.com/tutorials/install-and-configure-mod_rewrite-for-apache-on-centos-7/) for instructions.
 

#### Problem: SELinux blocks /usr/sbin/httpd from binding on port 9096
* **Potential Cause**: See your SELinux logs for confirmation and further details
* **Potential Solution**: Modify SELinux to allow httpd to bind on port:
```bash
ausearch -c 'httpd' --raw | audit2allow -M my-http
ausearch -c 'httpd' --raw | audit2allow -M my-http
```
* Try again: http://localhost:9096

* **Potential Solution 2**: Create a permissize SELinux module for httpd:
```bash
semanage permissive -a httpd_t
semanage permissive -l #Verify it worked. 
```
* **Potential Solution 3**: Allow httpd to connect to port 
9095 and 9096:
```bash
semanage port -a -t http_port_t -p tcp 9096
semanage port -a -t http_port_t -p tcp 9095
```

#### Problem: SELinux prevents httpd from connecting to DB on port 5432
* **Potential Solution**: 

    `setsebool -P httpd_can_network_connect 1`

### Problem: SELinux doesn't allow /usr/bin/sudo to access 'setrlimit'
* Error: `The source process /usr/bin/sudo attempted to access: setrlimit`
* **Potential Solution**: Set SELinux bool to allow httpd to access setrlimit:
```bash 
setsebool -P httpd_setrlimit 1
systemctl restart httpd
```
* Attempt to login again: http://localhost:9095

TO-DO, figure solution out to below or skpo
#### Problem: API Configuration gives error that your `directory path for new config files` is not writable by Apache
    #Potential Solution: make directory globally writable
    chmod 777 /opt/bacula/work





#### Problem: You see the following error when configuring the Config API at http://localhost:9096:
```
bacula-dir: ERROR TERMINATION at parse_conf.c:1118 Config error: "QueryFile" directive is required in "Director" resource, but not found. : line 20, col 1 of file /opt/bacula/etc/bacula-fd.conf } 17-Aug 14:43 bacula-dir: ERROR TERMINATION at parse_conf.c:1118 Config error: "QueryFile" directive is required in "Director" resource, but not found. : line 20, col 1 of file /opt/bacula/etc/bacula-fd.conf }
``` 
* **Potential Cause**: Contrary to what you might think after looking at this error, you might have simply supplied the wrong binary path. There are four different versions of the -json binary: `bdirjson`, `bsdjson`, `bfdjson`, and `bbconsjson`. They should all be located in `/opt/bacula/bin`

* **Potential Solution**: Make sure `sudo` is unchecked and modify the binary path for each category. For example, the bconsole binary path should be `/opt/bacula/bin/bbconsjson` and the config file path should be `/opt/bacula/bin/bconsole.conf`
## VNC TROUBLESHOOTING
### Problem: Black screen when trying to connect from client and 'gnome-shell killed by SIGTRAP' errors.
* **Possible Cause**: gnome may not be running on server. 
* **Possible Solution**: Reboot server, then log in as 'bacula.' Make sure the GUI appears. Then try initiating a connection via TigerVNC again

#
## PostgreSQL Troubleshooting:
#### Potential Envrionment Issues
* Is postgres in a "standard" location? the ./configure command for bacula takes a flag
for that, so not setting it could mean it was never found
* Note, Bacula assumes that `/var/bacula`, `/var/run`, and `/var/lock/subsys` exist, so it will not automatically create them during the install process.

#### Confirm that `postgres` user has correct priviledges:
```bash
su postgres
/usr/pgsql-9.6/bin/psql --command \\dp bacula
```

#### PostgreSQL authentication errors when checking `bacula-dir.conf` syntax with `./bacula-dir -t -c bacula-dir.conf`
```bash
[root@server.example bin]# ./bacula-dir -t -c bacula-dir.conf
bacula-dir: dird.c:1152-0 Could not open Catalog "MyCatalog", database "bacula".
bacula-dir: dird.c:1157-0 postgresql.c:309 Unable to connect to PostgreSQL server. Database=bacula User=bacula
Possible causes: SQL server not running; password incorrect; max_connections exceeded.
01-Aug 08:21 bacula-dir ERROR TERMINATION
Please correct configuration file: bacula-dir.conf
[root@server.example bin]# ./bacula-dir -t -c bacula-dir.conf
bacula-dir: dird.c:1152-0 Could not open Catalog "MyCatalog", database "bacula".
bacula-dir: dird.c:1157-0 postgresql.c:309 Unable to connect to PostgreSQL server. Database=bacula User=bacula
Possible causes: SQL server not running; password incorrect; max_connections exceeded.
01-Aug 09:19 bacula-dir ERROR TERMINATION
Please correct configuration file: bacula-dir.conf
```
##### Log from /var/lib/pgsql/9.6/data/pg_log/[..]:
```bash
< 2017-08-01 09:19:35.619 CDT > LOG:  provided user name (bacula) and authenticated user name (root) do not match
< 2017-08-01 09:19:35.619 CDT > FATAL:  Peer authentication failed for user "bacula"
< 2017-08-01 09:19:35.619 CDT > DETAIL:  Connection matched pg_hba.conf line 80: "local   all             all                                     peer"
```
#### Problem: Postgres was attempting to authenticate via 'peer authentication', while **md5** is specified in the `bacula-dir.conf` file.
* See for more details on authentication in PostgreSQL 9.6: [PostgreSQL Authentication Methods](https://www.postgresql.org/docs/9.6/static/auth-methods.html#AUTH-PASSWORD) 

#### Potential Solution 1:
* Restart postgres. This is sometimes required after making some configuration changes. 

    `systemctl restart postgresql-9.6`

#### Potential Solution 2:

* Change the 'local' entry for Unix domain socket connections from 'peer' to 'md5':
* See the error from `pg_log` to find what line you need to change (Line 80 in my case).

`vim /var/lib/pgsql/9.6/data/pg_hba.conf`

```
    host    all         all                 md5
``` 
#### Test above solution:
* `cd` to the directory with your Bacula binaries and run the test command:
```bash
cd /opt/bacula/bin #or `cd $BCE` if you used my custom environment variables
./bacula-dir -t -c bacula-dir.conf
```
* As long as postgres and `bacula-dir.conf` are configured correctly, no errors should appear in the terminal. 

#### For futher troubleshooting, monitor the postgres log while you run `./bacula-dir -t -c bacula-dir.conf`:
`tail -f /var/lib/pgsql/9.6/data/pg_log/<day>`

## `bconsole` ERRORS:

### Suggested approach to `bconsole` errors:
* Common issues are with 1.) Config files (mismatching names/passwords), 2.) Network Environment issue (SELinux/firewall conflicts)
* Very closely check all relevant config files to determine if there's a simple syntax error. 
    * It sounds trivial, but I have spent hours trying all kinds of troubleshooting, only to find the problem was a name/password mismatch
* See diagram to see how all names/passwords should connect across the server and client
    * If you're still unsure: temporarily change all passwords to "password" and see if it works. If possible, take a snapshot beforehand so you can revert back to its original state if this approach doesn't work. 
* Test if it's a config issue:
    `bacula-fd -tc /etc/bacula/bacula-fd.conf -d100`
* Test if it's a network issue.
    * Telnet from director to client over port 9102:
        * `telnet <client FQDN> 9102`
    * Telnet from client to director over port 9101:
        * `telnet <director FQDN> 9101`
* Test if it's an environment issue
    * Do client and server have same version of Bacula?
    * Temporarily disable SELinux, first on the client, then the server, then both:
        * `setenforce 0`
    * Restart PostgreSQL on your server. 
    * Make sure you have a hostname entry in `/etc/hosts` on your server
    * Re-configure and re-make `bacula-fd` on your client to check for compatibility errors. 
#### General `bconsole` Test: 
* Test the `bacula-dir` binary with the `bacula-dir.conf`:
```bash
cd $BCB #/opt/bacula/bin
bacula-dir -c /opt/bacula/etc/bacula-dir.conf -d100
```
#### Problem 1: Cannot connect to `bconsole` command line

##### Problem 1a:
* Running `bconsole` does not send you to the `bconsole` (*) command line. Instead, the command task simply hangs. 
* **Potential Cause 1**: Misconfiguration
* **Potential Solution**:
    * Restart bacula: `bac-restart`
    * If you have not done so already, test your `bacula-dir.conf` configuration
    * On one occasion, I ran into this problem when I misspelled a `Pool` entry in my `clients.conf`. On another, I mis-named one of my filesets in the **Name = "Name"** field in `filesets.conf`.

##### Symptoms 1b:
* Running `bconsole` does not send you to the `bconsole` (*) command. Running `./bconsole -c /opt/bacula/etc/bconsole.conf -d100` results in the following error: "bconsole:Could not connect to server Director daemon9101. ERR=Connection refused". 
* **Potential Cause 1**: The Console cannot connect to the director due to config file inaccuracies
* **Potential Cause 2**: Environment issues (firewall)
* **Possible Cause 3**: `bconsole` command is linking to the wrong binary. 
        
* **Possible Solution 1**: Make sure port `9101` is open in your firewall
    * `firewall-cmd --list-ports`
    * Try `telnet` commands
* **Potential Solution 2**:Remove the `DirAddress` section in your `bacula-dir.conf` file, if present

* **Potential Solution 3**: Make sure passwords and names across your configs are all compatible. See the the visual provided by [Bacula's Documentation](http://www.bacula.org/7.4.x-manuals/en/problems/Bacula_Frequently_Asked_Que.html#SECTION00260000000000000000)
    * TIP: If you changed your configs while attempting to add a new client, either create a backup of each config file in its current state (e.g. `bacula-dir.conf.new`). Then remove all the new changes you made from each config file and simply try to get `bconsole` to connect again. Once you have successfully restore functionality, slowly re-implement your changes to each file, stopping frequently to save and test to make sure `bconsole` works.

* **Possible Solution 4**: Launch a different binary by default
    * Test which one you're currently using `which bconsole`
    * If `/usr/sbin/bconsole`, try launching other bconsole binaries:
        ```bash
        /opt/bacula/etc/bconsole
        /opt/bacula/bin/bconsole
        ```            
        * If one of those works, and you plan on using Baculum - create softlink to the working binary:
        `ln -sf /opt/bacula/bin/bconsole /usr/sbin/bconsole`
            * This will make `/usr/sbin/bconsole` execute `/opt/bacula/bin/bconsole`
    * If one of those works, and you do not plan on using Baculum - rename the current bconsole:
    * Note - changing this will make the Baculum API test for console fail. 
    `mv /usr/sbin/bconsole /usr/sbin/bconsole.bak`
    * Alternatively, you could use a soft/hard link from `/usr/sbin/bconsole` to `/opt/bacula/bin/bconsole`

    
#### Problem2: "Waiting on FD" Error when running a backup
* **Possible Cause**: FD cannot communicate back to the Director.
* **Possible Solution**: Make sure you have the FQDN of the director listed in your bacula-fd.conf file, and not simply the hostname.
    * For example, if your Director's name in your bacula-dir.conf file is `bacula-test.domain.local-dir`, then you should use the same name in your bacula-fd file in the `Name` field for the Director section. Simply using `bacula-test-dir` (hostname + -dir) will not work.
* **Other possible causes**: Password mismatch
    * See Diagram (TO-DO: link to where this should be). 

#### Problem3: "Error: bsock.c:223 gethostbyname() for host "client.example.local" failed: ERR=Name or service not known"
* Possible Cause/Solution: Make sure your FQDN is spelled correctly in the Bacula configs and in your own environment.  
        
#### Problem4: Authentication error when connecting to bconsole:
* **Description**: Running `bconsole` gives the following error:
```
Director authorization problem.
Most likely the passwords do not agree.
If you are using TLS, there may have been a certificate validation error during the TLS handshake.
Please see http://www.bacula.org/en/rel-manual/Bacula_Freque_Asked_Questi.html#SECTION00260000000000000000 for help.
```  
#### Problem 5: Cannot find appendable volumes
* Description: Running a bacula backup jobs gives the below error:
```bash
Example-Job.2017-09-05_11.24.02_06 is waiting. Cannot find any appendable volumes.
Please use the "label" command to create a new Volume for:
    Storage:      "FileChgr1-Dev1" (/bacula/backup)
    Pool:         Exapmle-Pool
    Media type:   File1

```
* Possible Cause:
* Possible Solution:


## TO-DO either add or delete below two lines
* Possible Cause:
* Possible Solution:

#### `bconsole` `label` ERROR:
##### Error: 
```
Connecting to Storage daemon HPDrives at server.example.local:9103 ...
Sending label command for Volume "TestVol1" Slot 0 ...
3999 Device "FileStorage" not found or could not be opened.
Label command failed for Volume TestVol1.
Do not forget to mount the drive!!!
```
#### Solution 1: Closely compare your `bacula-dir.conf` and `bacula-sd.conf` files
* For me, I mistyped my hostname originally. After the fix, the `label` command worked fine. I never needed to do any `mount` commands
#### Potential Solution:
* Note - I have not verified that this works.
* Add entry to `/etc/fstab` for `/bacula` 

# BAT TROUBLESHOOTING
* Note, I attempted to configure BAT, but ran into so many issues that I gave up and went with Baculum instead. Nonetheless, I have included some errors and troubleshooting below in hopes to improve BAT documentation. 

#### Problem: Not having the right packages.
* **Potentail Solution**: 
    ```bash
    yum install -y qt-devel 
    yum install -y qwt-devel 
    ```
    * Might be better to install qt and qwt via the depkgs (below)
    * This seems to be needed for BAT GUI tool. Also installs qwt - http://wiki.bacula.org/doku.php?id=howto_compile_and_install_bacula_with_bat_on_fedora_7_or_centos_5`

#### Prolem: Errors when running Bacula's `./configure` command during installation
* **Potential Solution**: run `make distclean`, then run `setup.sh` script. Cleaning cache in this manner can help silly errors
* If that did not help, review the config.log file in `/tmp/bacula-9.0.3`
#### Problem when running `./setup.sh` script:	
```bash
configure: error: /bin/sh /usr/src/bacula-9.0.3/autoconf/config.sub   failed
./config.sh: line 7: --sysconfdir=/opt/bacula/etc: No such file or directory
./config.sh: line 9: --with-pid-dir=/opt/bacula/work: No such file or directory
```
* **Potential Solution** : Restart bacula components.

#### `qmake` issues when running ./setup.sh script:
```bash
configure: error: Could not find qmake /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/opt/bacula/bin. Check your Qt installation
```
* **Potential Solution**: Add directories with qt binaries to path
    * Find path: 
    `find / -name qmake`
        * Files here are mostly symlinks
    `find / -name qt4`    
    * add directory to path and retry:
    `export PATH=$PATH:/usr/lib64/qt4/bin` 

### `qtmake-qt4` error when running `./setup.sh` script:
`configure: error: Could not find qtmake-qt4 [..]` 
* **Possible Solution**: change path
* **Possible solution**: create symlink to the other qmake-qt4 binary:
```bash
which qmake-qt4
cd /usr/lib64/qt4/bin
ln -sf qmake /usr/bin/qmake-qt4
```

#### Cannot connect to X server
#Error:
```
bat: cannot connect to X server
```
* **Possible Cause**: X Windows is not installed in the OS. If Red Hat, perhaps just the Minimal Install was selected, which doesn't have X Windows.
    * At a minimum, you need the following installed: X server (Xorg), Desktop environment (Gnome or KDE, Display manager (gdm or kdm)
* **Possible Solution**: Install packages:
    * `yum groupinstall gnome-desktop  x11  fonts`
        * This should install around 2GB of packages
    * Set to boot directly to GUI:
        *  `systemctl set-default graphical.target`

### bat: error while loading shared libraries: 
`libbaccfg-5.2.13.so: cannot open shared object file: No such file or directory`

* **Possible Cause**: Bat is using libraries from version 5.2, when you're on a different version.See the Bacula documentation on [Fedora Project](https://fedoraproject.org/wiki/User:Renich/HowTo/Bacula)

* **Possible Cause**: You installed qt4, when bacula wants a different qt version. From [Bacula's Documentation](http://www.bacula.org/5.0.x-manuals/en/main/main/Installing_Bacula.html#SECTION0014100000000000000000): 
   ```
   Note, the depkgs-qt package is required for building bat, because bat is currently built with Qt version 4.3.4. It can be built with other Qt versions, but that almost always creates problems or introduces instabilities.
    ```
* **Possible Cause**: You didn't install 3rd party dependency packages before running `make` during the install process. See [Bacula Documentation](http://www.bacula.org/9.0.x-manuals/en/main/Installing_Bacula.html#SECTION001450000000000000000) for more information.






#### delete
### SET PASSWORDS
 ##### Note - the default passwords for Bacula might the same ( TO -DO: confirm).
 * The passwords were already set when getting to this point, so not sure if this step is necessary. Wouldn't hurt, though.
```bash
DIR_PASSWORD=`date +%s | sha256sum | base64 | head -c 33`
sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" opt/bacula/etc/bacula/bacula-dir.conf
sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" opt/bacula/etc/bacula/bconsole.conf

SD_PASSWORD=`date +%s | sha256sum | base64 | head -c 33`
sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" opt/bacula/etc/bacula/bacula-sd.conf
sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" opt/bacula/etc/bacula/bacula-dir.conf
 ```