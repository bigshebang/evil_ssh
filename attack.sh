#!/usr/bin/env bash
#evil ssh; ssh attack tool

if [ $# -gt 0 ]; then
	firstArg=$1
else
	read -p "Enter host: " host
	read -p "Enter username: " user
	read -p "Enter password: " pass
	firstArg="$user@$host"
fi

# echo "host $host"
# echo "user $user"
# echo "pass $pass"

echo "firstArg: '$firstArg'"

