# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:/opt/bacula/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

#Custom Bacula variables:
BC=/opt/bacula
BCB=/opt/bacula/bin
BCE=/opt/bacula/etc

export PATH
