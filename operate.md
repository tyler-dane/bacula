# Common Operational Tasks 
### References:
[List of Console Keywords and Commands (version 9)](http://www.bacula.org/9.0.x-manuals/en/console/Bacula_Console.html#SECTION00240000000000000000)


----

## Check Status of Backups:

#### Connect to Bacula server:
    `ssh <user>@<bacula-server-name>`
* For example: `ssh root@server.example.local`
#### 

#### Launch `bconsole` command line:
`bconsole`
* If you encounter "Command not found" errors, examine your $PATH and .bash_profile: 
    * `echo $PATH`
    * `vim ~/.bash_profile`
    * `source ~/.bash_profile`

#### List jobs:
`* list jobs`

* Note: The asterisk symbolizes the `bconsole` CLI; do not actually type it before commands. 
* For a legend of the status codes, see:
    * [List of JobStatus codes - Bacula Wiki](http://wiki.bacula.org/doku.php?id=faq)
    * [List of JobStatus codes - workaround.org](https://workaround.org/bacula-cheatsheet/)

#### List messages:
`* messages`

----
## Check Status of Volumes:

`bconsole`

`list volumes`

----

## Estimate Job:

