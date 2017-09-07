bacula-install-server.md

## Table of Contents
* TO-DOs
* NOTES
* SET UP THE SERVER ENVIRONMENT
* SET UP THE BACULA ENVIRONMENT
* INSTALL BACULA
* CONFIGURE POSTGRESQL
* CONFIGURE **bacula-dir.conf**	
* CONFIGURE **bacula-sd.conf**
* START & ENABLE COMPONENTS
* TEST CONSOLE FUNCTIONALITY
* TEST LOCAL BACKUP & RESTORE
* INSTALL & CONFIGURE CLIENT 
* ADD FILE SETS (ON SERVER)
* ADD CLIENT RESOURCE
* TEST SERVER-CLIENT CONNECTION
* TEST BACKUP JOB FOR CLIENT
* TEST RESTORE OPERATION FOR CLIENT
* OPTIONAL: INSTALL BACULUM GUI

#
### TO-DO:
* Finish:
    * Diagram of configs
    * Full example configurations
* Update Table of Contents
* Remove sections that are too specific
* Note that there is only one Bacula server in this architecture
* Note that its best to monitor system for at least a month before putting it into production so that you can tweak file sets and test monthly backup. It's also difficult to REDUCE the disk space that your backups take if the first file sets are restrictive enough for you needs.
* Look into PostgreSQL security in 
http://www.bacula.org/9.0.x-manuals/en/main/Installing_Configuring_Post.html
## NOTES
* These steps were tested on CentOS 7.4 and RedHat 7.4 systems.
* I use `vim`, but feel free to install and use whatever editor you like
* I use **PostgreSQL 9.6.3** as my database, but you can also **MySQL**
* The whitespace used in the YAML .conf files is different in Bacula version 9 as it is in version 5.5 (the version included in many package managers at the time of this writing), so be sure to adjust according to the version 9 standards if you copy and past from older versions. 

## SET UP THE SERVER ENVIRONMENT
### INSTALL NEEDED PACKAGES:
#### Basic Bacula Setup: 
`yum install -y policycoreutils-python ntp wget vim libzip-devel gcc gcc-c++ libacl-devel lzo-devel`
* As of 9.0.2, the Bacula team modified their code so that `lzo` and `libz (libzip)` shouldn't be necessary. Nonetheless, Bacula still recommends installing them both.

#### Bacula GUI packages (optional):
`yum install -y php-curl php-json php-mbstring`
* `policycoreutils-python` is needed for semanage command (below)
* `php-curl`, `php-json`, `php-mbstring` are needed for the baculum GUI
 
### Install repositories for Enterprise Linux (3rd party) and PostGreSQL 9.6.3:
```bash
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh epel-release-latest-7.noarch.rpm
rpm -Uvh https://yum.postgresql.org/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
```

#### Install postgres 9.6
``` bash
yum install -y postgresql96-server
yum install -y postgresql96-devel
/usr/pgsql-9.6/bin/postgresql96-setup initdb
systemctl enable postgresql-9.6.service 
systemctl start postgresql-9.6.service
#Check status:
systemctl status postgresql-9.6.service
```
* Side Note: If you ever want to remove postgres from your system, run: `yum erase postgresql96*`

### Check system time and sync if incorrect:
`date -R`
`ntpdate -u 0.us.pool.ntp.org`
### Open firewall ports:
```bash
firewall-cmd --permanent --zone=public --add-port=9101-9103/tcp
firewall-cmd --reload
```
### Verify that ports 9101 to 9103 are open:
`firewall-cmd --list-ports`

#### FQDN:
* If your client doesn't already have a Fully Qualified Domain Name (FQDN), assign it one.
*  I use server.example.local in this tutorial. 

## SET UP THE BACULA ENVIRONMENT
#### Create Bacula user:
```bash
useradd bacula
passwd bacula   
#Enter secure password
```
#### Add Bacula user to sudoers group:
```bash
usermod -aG wheel bacula
```

#### Create directories:
```bash
mkdir -p /bacula/backup 
mkdir -p /bacula/restore
chown -R bacula:bacula /bacula
chmod -R 700 /bacula

mkdir /opt/bacula/bin -p
mkdir /opt/bacula/etc
mkdir /opt/bacula/work 
```
#### Append the new bacula binary directory to your path:
`vim ~/.bash_profile`
```bash
#Make sure the 'export PATH' line comes *after* the path
PATH=$PATH:$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/opt/bacula/bin
export PATH
```
* Save and quit, then source your bash profile:
`source ~/.bash_profile`
    * Warning to those using terminal multiplexers: Do NOT execute this `source` command in multiple terminals during a single session. The result will be a long, ugly path. 

## INSTALL BACULA
`wget -O- https://sourceforge.net/projects/bacula/files/bacula/9.0.3/bacula-9.0.3.tar.gz/download | tar -xzvf - -C /tmp`

#### Create Configuration Script
`cd /tmp/bacula-9.0.3/`

`vim setup.sh`
```bash
#!/bin/bash

CFLAGS="-g -Wall" \
  ./configure \
    #--enable-bat \      #Only needed if you plan on using the BAT GUI (which can be very difficult to get to work) 
    --sbindir=/opt/bacula/bin \
    --sysconfdir=/opt/bacula/etc \
    --with-pid-dir=/opt/bacula/work \
    --with-subsys-dir=/opt/bacula/work \
    --enable-smartalloc \
    --with-postgresql=/usr/pgsql-9.6 \
    --with-python=/usr/bin/python \
    --with-working-dir=/opt/bacula/work \
    --with-dump-email=$USER
```

#### Run Configuration Script:
```bash
chmod +x setup.sh
./setup.sh
```
* Debug if errors. See 'TROUBLESHOOTING' section below


### Make and Install:
`make`
* It's critical that you do this before executing the `make install` command below
* Review the output of `make` carefully
* Debug if errors. See 'TROUBLESHOOTING' section below
`make install`
* Review output carefully

`make install-autostart`
* Autostarts Bacula components

#### Confirm that Bacula components start on boot:
```bash
systemctl reboot

service bacula-dir status
service bacula-fd status
service bacula-sd status
```
### OPTIONAL CONFIGURATION
* I often traverse the Bacula directories and restart components during configuration, so these variables/aliases save me a lot of time

##### Add environment variable to bash_profile:
`vim ~/.bash_profile`
```bash
#Custom Bacula variables: 
BC=/opt/bacula
BCE=/opt/bacula/etc
BCB=/opt/bacula/bin
```
`source ~/.bash_profile`

#### Edit bashrc with aliases:
`vim ~/.bashrc`
```bash
alias bac-status='service bacula-dir status & service bacula-sd status & service bacula-fd status'

alias bac-restart='service bacula-dir restart && service bacula-sd restart && service bacula-fd restart'
```
`source ~/.bashrc`

### Test variables and aliases:
```bash
cd $BC
cd $BCE
cd $BCB

bac-status
bac-restart
```

## CONFIGURE PostgreSQL
* Reference: 
[Configuring PostGreSQL - Bacula Documentation](http://www.bacula.org/9.0.x-manuals/en/main/Installing_Configuring_Post.html)
* See below section for PostgreSQL troubleshooting. 

#### Give PostgreSQL permissions needed to run scripts below (???)

`chown -R postgres:postgres /opt/bacula/etc/` 
* You'll run the `./create.` command as this user (?)
#### Create a `strongpassword` to use for PostgreSQL and your `bacula` user:
```bash
echo `date +%s | sha256sum | base64 | head -c 15`
```
* Uses epoch `date` to create shasum , encodes with base64, and outputs 15 characters from sequence
* Save this for future steps in this tutorial

#### Create PostgreSQL **bacula** user
`su postgres`

`psql`
* This will take you to the psql command line

`createuser -s bacula`
* This includes needed privledges to createdb and create users.
This installs to the 'cats' directory, but those binaries are linked here.
* You may see `could not change directory to [x]: Permission denied` errors. This may not be a seriouis error. To check if the `bacula` user was still successfully check the output of the `\du` command:
    * ```bash 
        psql
        \du
        ```
#### Insert the password you previously created for the `bacula` PostgreSQL user:
```bash
psql bacula
alter user bacula with password 'strongpassword';
#(ALTER ROLE)
\q
```
* Skipping this still will make it diffuclt to later run `bacula-dir -tc /opt/bacula/etc/bacula-dir.conf`

### Create Bacula Database, make tables, and grant privileges:
* Run this as the 'postgres' user:
```bash
cd /opt/bacula/etc
./create_bacula_database
./make_bacula_tables
./grant_bacula_privileges 
```
* You should get a messages: 
    * `Creation of bacula database succeeded`
    * `Creation of Bacula PostgreSQL tables succeeded`
    * `Privileges for user bacula granted on database bacula.`

#### Switch back to root:
`su root` or CTL+D

#### Configure postgres to use 'md5' authentication instead of 'peer' 
`vim /var/lib/pgsql/9.6/data/pg_hba.conf`

##### Scroll to the bottom section and create a new entry for bacula user,db and md5 authentication. Also create an entry for your Bacula Server's IP. For example:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   bacula          bacula                                  md5
host    bacula          bacula          172.16.3.60/24          trust
```

##### Switch back to root: 
`su root` or CTL+D

#### Add `strongpassword` for PostgreSQLto `bacula-dir.conf` to allow for authentication:


`vim /opt/bacula/etc/bacula-dir.conf`
* Update sections with your `strongpassword`:
```bash
# Backup the catalog database (after the nightly save)
Job {
  Name = "BackupCatalog"
  #[...] Sections ommitted for clarity.
  RunAfterJob  = "/opt/bacula/etc/delete_catalog_backup strongpassword"
   #[...] Sections ommitted for clarity.
}
#[...] Sections omitted for clarity.
Catalog {
  Name = MyCatalog
  dbname = "bacula"; dbuser = "bacula"; dbpassword = "strongpassword"
}
```

#### Start PostgreSQL:
`touch /var/lib/pgsql/9.6/data/logfile`

`postgres -D /var/lib/pgsql/9.6/data/pg_xlog/ >logfile 2>&1 &`
* A PID should return, indicating that the PostgreSQL process is running.
* See the PostgreSQL entries in the **TROUBLESHOOTING** section at the bottom of this tutorial if you run into issues.

#### Restart PostgreSQL:
* It seems unnecessary to do this right after starting it, but I found that the changes I made to the postgres config files did not stick until after I restarted it.
    `vim /var/lib/pgsql/9.6/data/pg_hba.conf`
#
## CONFIGURE **bacula-dir.conf**
* Add `DirAddress` to  restrict what IP addresses Bacula will use for IP binding.
* Make sure backups are compressed
* Specify `FileSet`
* See full *bacula-dir.conf* sample file [To-Do: Specify where they can find this file]. 
 Make sure 'Catalog{}' section is updated with postgres password (detailed in PostgreSQL section above)
* Consider making **Job** names more intuitive
* Consider updating the **email** field with an external email
* The default `bacula-dir.conf` has a lot of comments. Mine are preceeded by the: `#!!` sign.
* `bacula-dir.conf` is a big file, so only the sections that I changed are included below. For a full example of the file, see # TO -DO: include reference. 

`vim /opt/bacula/etc/bacula-dir.conf`

```bash
Job {
  Name = "RestoreLocalFiles"
  Type = Restore
  Client=server.example.local-fd
  Storage = File1
# The FileSet and Pool directives are not used by Restore Jobs
# but must not be removed
  FileSet="BaculaConfigs-Home-Root"
  Pool = LocalFiles
  Messages = Standard
  Where = /bacula/restore #!! Previously: /tmp/bacula-restore
}

FileSet {
  Name = "BaculaConfigs-Home-Root"
  Include {
    Options {
      signature = MD5
      compression = GZIP    #!! Added this option to save disk space.
    }

    File = /opt/bacula/
    File = /home
    File = /root
  }

  Exclude {
    File = /bacula ## No need to back up your backup files to the same Bacula server twice.  
  }
}
 
#!! Add 'Storage {}' section above the Autochanger {} section

Storage {
  Name = File 
  Address = server.example.local
  SDPort = 9103
  Password = "0NbfHREkVIjoIDaIszRBZFBtaMBWbHCy+e0by3HKWOOZ" ## Paste password from Autochanger {} section below
  Device = HP-Drives
  Media Type = File 
} 

##! Optional: tweak the "Default pool definition" and "File Pool definition" sections to you needs:
# Default pool definition
Pool {
  Name = Default
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 365 days         # one year
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
  Maximum Volumes = 5               # Limit number of Volumes in Pool
}

# File Pool definition
Pool {
  Name = LocalFiles
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 365 days         # one year
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
  Maximum Volumes = 5               # Limit number of Volumes in Pool
  Label Format = "LocalVol-"               # Auto label
}

@|"find /opt/bacula/etc/conf.d -name '*.conf' -type f -exec echo @{} \;" # !! Add below line to end of file to link bacula-dir.conf with new config files. (These will be created in shortly in the tutorial)
```

#### Check for syntax errors in *bacula-dir.conf*:

`cd /opt/bacula/bin`
* or `cd $BCB`

`bacula-dir -tc opt/bacula/etc/bacula-dir.conf`

#
## CONFIGURE **bacula-sd.conf**:
`vim /opt/bacula/etc/bacula-sd.conf`
* Only sections that need to be changed are included here. Refer to (TO-DO - list) for a fully copy of **bacula-sd.conf**
* See `#!!` comments for instructions on what to change: 

```bash
Storage {                             # definition of myself
  Name = server.example-sd
  SDPort = 9103                  # Director's port
  WorkingDirectory = "/opt/bacula/work"
  Pid Directory = "/opt/bacula/work"
  Plugin Directory = "/usr/lib64"
  Maximum Concurrent Jobs = 20
  SDAddress = server.example.local     #!! Add SDAddress line with your FQDN
}
#!! Add Device {} section below
Device {
  Name = HP-Drives
  Media Type = File
  Archive Device = /bacula/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no; 
}

#!! Change `Archive Device` section for each changer from /tmp to /bacula/backup. This sets where Volumes are saved.

Device {
  Name = FileChgr1-Dev1
  Media Type = File1
  Archive Device = /bacula/backup   #!! previously /tmp

#!! Repeat for each Device {}
```
#### Check for sytax errors in your storage config file
```bash
cd /opt/bacula/bin
bacula-sd -tc /opt/bacula/etc/bacula-sd.conf
```

## START & ENABLE COMPONENETS

#### Start services:

```bash
systemctl start bacula-dir
systemctl start bacula-sd
systemctl start bacula-fd

systemctl status bacula-dir
systemctl status bacula-sd
systemctl status bacula-fd
```
* If you added the optional aliases to your bash profile, you could simply run `bac-restart` and `bac-status`

#### If each component started correctly, enable them to start on boot:
```bash
systemctl enable bacula-dir
systemctl enable bacula-sd
systemctl enable bacula-fd 
```
## TEST CONSOLE FUNCTIONALITY:
`bconsole`
* You should enter the console command line, indicated by an asterisk (*). 
* See troubleshooting options if you have issues here.
* TO-DO - make reference more specific
#
## TEST LOCAL BACKUP & RESTORE
* For reference, see Blue Ocean's [How to Install Bacula Server on CentOS](https://www.digitalocean.com/community/tutorials/how-to-install-bacula-server-on-centos-7) for more detail.
```bash
bconsole
label
2 # Or whichever number corresponds to your LocalFiles volume
Enter new Volume name: TestVol #Or any other name you prefer
# The output should be something like: "3000 OK label. VolBytes=240 VolABytes=0 VolType=1 Volume="TestVol" Device="HP-Drives" (/bacula/backup)"
run
yes
1   #Or whichever number corresponds to your BackupLocalFiles job
# You should see a command line prompt saying "You have messages." To view messages, simply enter: 
messages
# If you did not receive the prompt after a couple minutes, use these commands to check on the backup status:
status director
status jobid=#the jobid of the backup #status job=1
list jobs   #Review the job status column
```
#### Once a backup terminates successfully, run a test restore operation:
```bash
bconsole
restore
5 # Selects the most recent backup
1 # For our BaculaConfigs-Home-Root job
mark * # Selects all files for backup
done
yes
messages

```
### Optional: CUSTOMIZE LOCAL BACKUP & RESTORE
* Now that you have the basic functions of Bacula work on your system, consider customizing the configurations. You could, for example, change the naming conventions for the `FileSets`,  and `Storage` fields to more specifically describe your environment. 
* After renaming, be sure to re-run the test backup and restore operations

#### Generate random password that will be used to authenticate the client and director. Even though the password field is already filled out, it's important that you create your own, because it looks like those are default passwords.

`date +%s | sha256sum | base64 | head -c 33 ; echo`    
* e.g.: ZDNiYmZlYzY2MTY1NDljYjQ0MDU1YmZlM
#
## INSTALL & CONFIGURE CLIENT 
* Client is named `client.example.local` in this example
* Before continuing, following the instructions in [bacula-install-client.md](bacula-install-client.md) for installing Bacula on a client system. Return to this file when instructed.
* Also Reference Digital Ocean's [How to Backup a CentOS 7 Server with Bacula](https://www.digitalocean.com/community/tutorials/how-to-back-up-a-centos-7-server-with-bacula)

### ADDING A CLIENT - **OVERVIEW**

1. On Client:
* Decide what you need to back up for the client
* Install and configure Bacula File Daemon
* Copy password from bacula-fd.conf

2. On Server:
* Create custom file set in **filesets.conf** based on what your client needs backed up
* Add new `Client {}` and `Job{}` sections in clients.conf
* Create custom file set for Client in **filesets.conf**
* Create custome pool for Client in **pools.conf** (Optional)

### ADDING A CLIENT - **STEP-BY-STEP**
* The below steps should be taken on the Bacula **Server** - not the Client.


### ORGANIZE BACULA configs by creating a new dir and using separate files
`mkdir /opt/bacula/etc/bacula/conf.d`
* This step is only needed when adding your first client

### Add new Pool for Client:
```bash
cd /opt/bacula/etc/conf.d/
vim pools.conf
```

#### Add below pool resource, customizing configurations to your needs:
```bash
Pool {
  Name = Client1
  Pool Type = Backup
  Label Format = DB-Tests-
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 180 days         # one year
    Maximum Volume Bytes = 30G          # Limit Volume size to something reasonable
  Maximum Volumes = 10               # Limit number of Volumes in Pool
}
```

## ADD FILE SETS
#### Create/Edit *filesets.conf* file:
* This step is only needed if you would like to create a custom FileSet for your client. Skip this step if you are OK with using Bacula's generic FileSets.

`vim /opt/bacula/etc/conf.d/filesets.conf`

```bash
FileSet {
  Name = "Oracle-DB"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
    File = /etc/bacula
    File = /home/thitzeman
    File = /etc/oracle-db
  }
  Exclude {
    File = /etc/bacula/tapealert
    File = /etc/bacula/do-not-backup
    File = /home/thitzeman/do-not-backup
  }
}
```

## ADD CLIENT RESOURCE 
* This is needed so that Server can connect to Clients

`vim /opt/bacula/etc/conf.d/clients.conf`
```bash
Client {
  Name = clientA.example.local-fd
  Address = client.example.local
  FDPort = 9102 
  Catalog = MyCatalog
  Password = "D" # password for Remote FileDaemon. Should match PW in the Client's bacula-fd.conf
  File Retention = 30 days             
  Job Retention = 3 months            
  AutoPrune = yes                     # Prune expired Jobs/Files
}

Job {
  Name = "Client1"
  JobDefs = "DefaultJob"
  Client = client1-example.local-fd
  Pool = Client1    
  FileSet="Client1"
}

```    
#
## TEST SERVER-CLIENT CONNECTION

#### Restart File Daemon on Client:
`service bacula-fd restart`
#### Restart Bacula services on Server:
`bac-restart`    
* previously created alias. See ~/.bash_profile

`bac-status`

* Command comes from previously created alias.  [/bacula/configs/.bash_profile](https://github.com/tyler-hitzeman/bacula) for an example of the ~/.bash_profile. 
* To-do: ^Update the reference here

`bconsole`

`status client`

`(the number of your new client)`

* There should immediately be output that lists the running jobs and info about the client

#### Possible Error 1:
```bash
    bacula-test1-dir JobId 0: Fatal error: Unable to authenticate with File daemon at "172.16.4.11:9102".

 Possible causes:
    * Passwords or names not the same or
    * Maximum Concurrent Jobs exceeded on the FD or
    * FD networking messed up (restart daemon)
```
##### Debugging Error 1:
* Make sure name and password are the same for client in `bacula-dir.conf` and `clients.conf`. Do not confuse this password with the generic `bacula-dir.con`f` password - that one should never go on a client's config file.
* Make sure the Director's **Name** field indeed points to the Bacula **Server** and not the local **Client** that you are installing.
*Similarly, check that Director's **Name** field has 'dir' suffix (e.g., `client.example.local-dir`)
* Make sure to restart the `bacula-dir`, `bacula-fd`, and `bacula-sd` services on the server and the `bacula-fd` service on client after making config changes.

# 
## TEST BACKUP JOB FOR CLIENT
```
bconsole
run
4       #Enter whatever number corresponds to your client
yes
```

#### Check on your job. 
* Below are three commands to show you the status of your job. Review outputs closely and troubleshoot any errors.

`* list jobs`

`* status director`

`* messages`
* You should see a line saying: "Termination: Backup OK"

* Look at the `jobstatus` column. `T` indicates successful termination. `f` indicates job failure.
#
## TEST RESTORE OPERATION FOR CLIENT
```
bconsole
restore all     #If you're testing a large backup, you might be better off simply running `restore`. Running`restore all` can quickly make the client machine run out of disk space.
5
done
yes
messages
```
* Review output closely and troubleshoot any errors.

#### Potential Error: `Error: mkpath.c:140 Cannot create directory /bacula/restore/home: ERR=Permission denied`
#### Symptom:
* `messages` shows `Backup--with errors`

#### Cause: SELinux on Client machine

#### Solution: change policy for `/bacula/restore` directory
* Disable SELinux (`setenforce 0`) on client and server and retry backup
* If there were no errors when running restore operation with SELinux off, then turn SELinux back on and run the below commands on the Client to modify the SELinux policy:

```bash
chcon system_u:object_r:bacula_store_t:s0 /bacula/restore
semanage fcontext -a -t bacula_store_t "/bacula/restore(/.*)?"
restorecon -R -v /bacula/restore
ls -lZ /bacula #displays security context for directory
```            
* Reboot Client: `systemctl reboot`
* Retry the restoring your backup. At this point, it should work. 
* After completing the above, create a new file, back it up, and test restoring it.

#
## OPTIONAL: INSTALL BACULUM GUI
* If you are OK with administering Bacula from the `bconsole` command line, then this step is not necessary. 
* However, I find that having a GUI is useful for the following reasons:
    * The graphs, charts, and windows make it easier to gain an overview of your environment and troubleshoot.
    * The GUI allows novices to immediately monitor and opeate Bacula , instead of having to first spend a lot of time learning the `bconsole` commands
* I use the Baculum GUI in this tutorial. I found their product and documentation superior and easier to use than other GUI solutions, like *BAT* and *Bacula Web*. 
* See **BACULUM GUI TROUBLESHOOTING** section in [bacula-troubleshooting.md](bacula-troubleshooting.md)  if you run into issues.

#### Backup Bacula config files:
* On first `save config` action the Bacula configuration is joined into one file per Bacula component, so back up your config files in case your configuration breaks. 

```bash
mkdir -p /tmp/bacula/configs.bak
cp -r /opt/bacula/etc/*.conf /tmp/bacula/configs.bak/
cp -r /opt/bacula/etc/conf.d/*.conf /tmp/bacula/configs.bak/
```
### Install CentOS GUI:
`yum group install -y gnome-desktop x11 fonts`

### Configure server to boot in graphical mode by default:
```bash
systemctl set-default graphical.target 
systemctl reboot
#I needed to run the above twice before it worked. 
```
#### Note on GUI Access:
Of course, you'll need access to the server's graphical interface for the Bacula GUI to be useful. If connecting a monitor directy to the server is not an option, then you can install a VNC on your client machine and access your Bacula Server's GUI remotely. I use **TigerVNC** in this tutorial. Jump down to the **INSTALL TIGERVNC** section below for instructions.

### INSTALL BACULUM
* See [Bacula's Baculum Documentation](
http://www.bacula.org/9.0.x-manuals/en/console/Baculum_API_Web_GUI_Tools.html#SECTION00310000000000000000) and make sure your system meets the General Requirements. 
* They should've been installed when setting up the environment

#### Check PHP and Apache modules with:
```
php -m
httpd -M
```

### Add Baculum RPM repository:
```
rpm --import http://bacula.org/downloads/baculum/baculum.pub
yum install baculum-common baculum-api baculum-api-httpd #baculum-http baculum-selinux (?) #baculum-web
```

`vim /etc/yum.repos.d/baculum.repo`
* Copy and paste the below:
```
[baculumrepo]
name=Baculum CentOS repository
baseurl=http://bacula.org/downloads/baculum/stable/centos
gpgcheck=1
enabled=1
```
#### Add baculum user to sudoers group:
`vim /etc/sudoers.d/baculum`
```bash
[...] from doc #TO-DO - figure this out
```

#### Install the Baculum API for the Apache Web server:
```bash
yum install baculum-common baculum-api baculum-api-httpd
service httpd restart       #I had to disable SELinux
```
#### Start Apache on boot:
`systemctl enable httpd`

#### Configure PostGreSQL to accept tcp/ip connections over port 5423(?):

##### Add `bacula` entry to `pg_hba.conf`:
`vim /var/lib/pgsql/9.6/data/pg_hba.conf`
* This may be in a differet location on non-Red Hat systems

```bash
# TYPE  DATABASE        USER            ADDRESS                 METHOD

host    bacula          bacula          `192.168.2.20/24          trust
```
* Add the above line, substituting the *Address* field with the IP of your Bacula server.

##### Add address to `postgresql.conf`:
`vim /var/lib/pgsql/9.6/data/postgresql.conf`
* Uncomment `listen_addresses` line and enter your IP. 
* Also uncomment the line for 'port = 5432' 
    * TO-DO: confirm whether you actually need this
```bash
listen_addresses = 'localhost,192.168.2.20'
port = 5432
```
#### Restart Postgres
`systemctl restart postgresql-9.6.service`

### Connect to Baculum and Configure Apache:

#### Install all needed packages, then restart Apache:
```bash
yum install baculum-common baculum-web baculum-web-httpd
service httpd restart
```
#### Try signing in:
http://server.example.local:9095
or
http://localhost:9095

#### Configure. See Bacula's [Baculum Documentation](http://www.bacula.org/9.0.x-manuals/en/console/Baculum_API_Web_GUI_Tools.html#SECTION00360000000000000000) for instructions.
* Be sure to record the passwords you create - you'll need them to reconnect later. 

### Optional: Configure Baculum API
* Note: If you only want to monitor and manager Bacula via the web GUI, then configuring the API might not be necessary. The API simply responds to POST requests with JSON data. In my case, that was not very useful. 

http://server.example.local:9096
#### See [screenshots](http://www.bacula.org/9.0.x-manuals/en/console/Baculum_API_Web_GUI_Tools.html#SECTION00371000000000000000) for configuration examples
#### Enter [configuration options](http://www.bacula.org/9.0.x-manuals/en/console/Baculum_API_Web_GUI_Tools.html#SECTION00371000000000000000)

#
### INSTALL TIGERVNC
#### For reference, see Digital Ocean's [How to Install and Configure VNC Remote Access for the Gnome Desktop on CentOS7](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-remote-access-for-the-gnome-desktop-on-centos-7)

`yum install -y tigervnc-server`
*Installs version 1.3.1-9el7 on CentOS as of 08/16/2017

### Configure TigerVNC
* Make copies of generic VNC service unti file with the VNC subport:
```bash
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:4.service
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:5.service
```

`vim /etc/systemd/system/vncserver@:4.service`
* Replace <USER> with `bacula`
* Add -geometry 1280x1024"

`vim /etc/systemd/system/vncserver@:5.service`
* Replace <USER> with `bacula`
* Add -geometry 1280x1024"

#### Reload:
`systemctl daemon-reload`

#### Create symlinks to enable servers:
```bash
systemctl enable vncserver@:4.service
systemctl enable vncserver@:5.service
```
#### Configure firewall:
##### Verify firewall is running:
`firewall-cmd --state`
##### Add ports 5904 and 5905:
```bash 
firewall-cmd --permanent --zone=public --add-port=5904-5905/tcp
```
#### Reload firewall and list ports to confirm:
```bash
firewall-cmd --reload
#TO-DO: add --list units firewallcmd command
```
#### Set VNC Paswords:
```bash
su bacula
vncserver
```
* Enter the password you created earlier when prompted

#### Reload services:
```bash
systemctl daemon-reload
systemctl restart vncserver@:4.service
systemctl restart vncserver@:5.service
```

#### Setup VNC on Client:
`yum install tigervnc`
* Worked on my Fedora 25.

#### Open VNC from Applications menu
* Enter ip and port of server, then click `Connect <IP>:5904`  
     * For example: `192.160.0.20:5904`

#### Enter the VNC password for the user you created to connect to the 5904 port
* Note: This is not necessarily the same password as the Centos user's password

#### SECURITY TIP - Using SSH Tunnel/port forwarding to secure VNC Session:
`ssh -L 5900:172.16.4.18:5905 bacula@172.16.4.18 -N`
 * Enter bacula's user pw. The connection will appear to hang, but you can keep it running as along as you use the remote desktop.
#
