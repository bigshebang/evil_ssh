evil_ssh
========

This tool builds an expect script that is designed to start an SSH connection on a target computer. Therefore, expect must be installed for this to work. The script expects you to already know the credentials of a sudo or root user on your target. Once logged in, the tool changes the root password, creates a backdoor user, starts and stops some services, and flushes current firewall rules, all while remaining pretty stealthy. 

Customizability
===============

This tool allows you to specify a few different options in order to customize your attack to your needs or preferences. You can decide the following: 
* SSH port used on target
* Which services are started and which are stopped on the target
* Name, password and UID of the backdoor user added to the target
* New password of the root account
* How stealthy you want the script to be
* More to come

By default, the root and backdoor user passwords are both changed to "Password!" and the backdoor user is created with UID 0, and added to the root, adm, sudo and wheel group (numerous groups included to be more compatible). 

The services stopped by default are as follows:
* iptables
* ipfw
* ipf
* pf

The services started by default are as follows:
* xinetd
* inetd
* ssh/sshd
* cron/crond
* anacron
* cups
* portmap
* nfs, nfslock
* rpcbind
* rpcidmapd
* smb/smbd/sambda
* rsync, rsh, rlogin



