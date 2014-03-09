#!/usr/bin/env bash
#evil ssh; ssh attack tool

port=22
if [ $# -gt 0 ]; then
	firstArg=$1
	pass=$2
else
	read -p "Enter host: " host
	read -p "Enter username: " user
	read -p "Enter password: " pass
	read -p "Enter port: " port
	firstArg="$user@$host"
fi


# echo "host $host"
# echo "user $user"
# echo "pass $pass"

echo "command would be ssh $firstArg -p $port"
echo "attemping login"

# /usr/bin/expect -c 'spawn ssh test@127.0.0.1; expect "*assword:*"; send "password\n"; interact'

# /usr/bin/expect -c "
# 	spawn ssh test@127.0.0.1
# 	set prompt :|#|\\\$
# 	interact -o -nobuffer -re $prompt return
# 	send "password\r"
# 	interact -o -nobuffer -re $prompt return
# 	send "ls\r"
# 	interact -o -nobuffer -re $prompt return
# 	send "cat /tmp/file\r"
# 	interact
# "

# /usr/bin/expect -c "  
#    set timeout 1
#    spawn ssh test@127.0.0.1
#    expect yes/no { send yes\r ; exp_continue }
#    expect password: { send $pass\r }
#    expect '*'
#    send "ls -la \r"
#    interact
# "

   # expect *: { send ls\r }
   # expect *: { send ls\r }
   # expect *: { send exit\r }

cat <<EOF > myfile.exp
#!/usr/bin/expect

spawn ssh $firstArg
#use correct prompt
set prompt ":|#|\\\$"
interact -o -nobuffer -re \$prompt return
send "$pass\r"
interact -o -nobuffer -re \$prompt return
send "ls\r"
interact -o -nobuffer -re \$prompt return
send "echo 'balls2' >> /tmp/file\r"
interact -o -nobuffer -re \$prompt return
send "exit\r"
interact

EOF
echo "after making file"
# exit 0
/usr/bin/expect myfile.exp

# works? NOPE
# /usr/bin/expect -c '
# spawn ssh test@127.0.0.1
# expect "*password:*"
# send "$pass\n"
# interact
# '

#doesnt work
# /usr/bin/expect <<EOD
# spawn ssh test@127.0.0.1
# expect "*assword:*"
# send "password\n"
# interact
# EOD
#kinda works!!!!
# /usr/bin/expect -c 'spawn ssh [lindex $argv 0] 'ls'; expect "*assword:*"; send "password\n"; interact' $firstArg
#doesn't work
# /usr/bin/expect -<<COMMANDS
# spawn ssh $firstArg
# expect "*"
# send "$pass\r"
# expect "*"
# send "echo 'test successful!' >> /tmp/file\r"
# expect "*"
# send "exit\r"
# COMMANDS

echo "after expect"

