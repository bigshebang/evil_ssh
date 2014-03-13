evil_ssh
========

This tool builds an expect script that is designed to start an SSH connection on a target computer. The script expects you to already know the credentials of a sudo or root user on your target. Once logged in, the tool changes the root password, creates a backdoor user, starts and stops some services, and flushes current firewall rules, all while remaining pretty stealthy. 

Customizability
===============


