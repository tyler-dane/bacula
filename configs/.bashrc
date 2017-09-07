# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Bacula-specific aliases:
alias bac-status='service bacula-dir status & service bacula-sd status & service bacula-fd status'

alias bac-restart='service bacula-dir restart && service bacula-sd restart && service bacula-fd restart'


# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
