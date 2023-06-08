# Bacula

*"Just as we respect and care for our ancestors, so we must respect and care for our old backups, for one day they may achieve great glory." - [Tao of Backup](http://www.taobackup.com/index.html)*

Backups are important. Bacula, an open-source client/server backup program, may be a good option for those intersted in automating their backups. 

This repository contains instructions and configuration files for installing and using Bacula.

#### Author: [Tyler Dane](https://github.com/tyler-dane)

----

### Step 1: Learn about Bacula
* You should have a general understanding of the following topics before attempting to install and use Bacula:
    * The architecture (i.e., how `bacula-dir`, `bacula-sd`, and `bacula-fd` interact)
    * The `bconsole` command line
    * What version best meets your needs. I use version 9.0.3.
    * How to develop a suitable [Disaster Recovery Plan](http://www.bacula.org/5.0.x-manuals/en/main/main/Disaster_Recovery_Using_Bac.html)  for you Bacula instance.

#### Read through Bacula's documentation at [blog.bacula.org]([http://blog.bacula.org/what-is-bacula/])


#### Read through [Blue Ocean's Guides](https://www.digitalocean.com/community/tutorial_series/how-to-use-bacula-on-centos-7)
* These are well written and straightforward. 
* If you want to start using Bacula as quickly as possible, I recommend simply following those guides. 
* If you want to customize your Bacula instance by using a newer version and optimizing configurations, however, I suggest using my documentation as a supplemental resource.  

#### Review the [Configuration File Diagram](password-chain.jpg) provided in this repository

#### Review the sample [Raw Configuration Files](https://github.com/tyler-hitzeman/bacula/tree/master/configs) provided in this repository.

-----

### Step 2: [Install Bacula Server](install-server.md)
* This tutorial demonstrates how to install Bacula *Server* on a CentOS 7 system.

----
### Step 3: [Install Bacula Client](install-client.md)
* This tutorial demonstrates how to install Bacula *Client* on a CentOS 7 system.

----

### Step 4: [Operate Bacula](operate.md)
* This document details how to execute common Bacula tasks, such as checking the status of backups and volumes.

----
### Stuck? See if your problem is covered in the [Troubleshooting File](troubleshooting.md)




