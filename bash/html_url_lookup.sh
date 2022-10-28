#!/bin/bash

ARG1=$1

# Color Constants
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;37m'
PURPLE='\033[1;35m'
NC='\033[0m' #No Color
BOLD=$(tput bold)
NS=$(tput sgr0) #No Style

VERSION="1.0"

banner() {
	echo "
	 _               _   _                 _
	| |__   ___  ___| |_| |__  _   _ _ __ | |_
	| '_ \ / _ \/ __| __| '_ \| | | | '_ \| __|
	| | | | (_) \__ | |_| | | | |_| | | | | |_
	|_| |_|\___/|___/\__|_| |_|\__,_|_| |_|\__|
	"

	echo "                       hosthunt v${VERSION}"
	echo
	echo "        Usage: $0 [OPTIONS] [URL]"
	echo "         Example: $0 example.com"
	echo
	echo "                  Use -h for further help"
}

prerun() {
	# Check if system has all dependencies needed to run the script
	if ! [[ -e /usr/bin/wget ]]; then
		echo "${RED}Missing dependency: ${BOLD}/usr/bin/wget${NC}${NS}"
		exit 1
	fi

	if ! [[ -e /usr/bin/host ]]; then
		echo "${RED}Missing dependency: ${BOLD}/usr/bin/host${NC}${NS}"
		exit 1
	fi

	# See if any arguments were passed
	if [[ $ARG1 == "" ]]; then
		banner
		exit 1
	fi
}

helper() {
	echo "NAME"
	echo "hosthunt - find links and their hosts inside a webpage."
	echo
	echo "DESCRIPTION"
	echo "A bash script that parses a page's HTML code and finds active IP addresses for every link found."
	echo
	echo "OPTIONS"
	echo "-h | --help"
	echo "Opens the help page."
	echo
	echo "-v | --version"
	echo "Shows current version."
	echo
	echo "-f | --file"
	echo "Search for hosts in specific file."
	echo "Example: $0 -f myfile.txt"
}

cleanup() {
	rm -rf /tmp/1 &>/dev/null
}

download_page() {
	cleanup
	mkdir /tmp/1 && cd /tmp/1

	echo "{+} Downloading HTML..."

	if wget -q -c --show-progress $ARG1 -O file; then
		echo "${GREEN}{+} Download complete.${NC}"
	else
		echo "${RED}{+} Download failed.${NC}"
		exit 1
	fi
}

parse_html() {
	sed -i "s/ /\n/g" file
	grep -E "(href=|action=)" file > .tmpfile1

	grep -oh '"[^"]*"' .tmpfile1 > .tmp2
	grep -oh "'[^']*'" .tmpfile1 >> .tmp2

	sed -i 's/"//g' .tmp2
	sed -i "s/'//g" .tmp2

	grep "\." .tmp2 | sort -u > links
}

get_hosts() {
	cp links tmplinks
	sed -i "s/?/\n/g
			s/\/\/\//\n\/\//g" tmplinks

	grep -oh "//[^/]*/" tmplinks > .tmpfile10
	grep -oh "//[^/]*" tmplinks >> .tmpfile10
	grep -oh "ww.*\.br" tmplinks >> .tmpfile10
	grep -oh "ww.*\.net" tmplinks >> .tmpfile10
	grep -oh "ww.*\.gov" tmplinks >> .tmpfile10
	grep -oh "ww.*\.org[^.]" tmplinks >> .tmpfile10
	grep -oh "ww.*\.com[^.]" tmplinks >> .tmpfile10

	sed -i "s/\///g" .tmpfile10
	grep "\." .tmpfile10 | sort -u > hosts
}

get_live_hosts() {
	echo
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo -e "${CYAN}                            Active Hosts                                        ${NC}"
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo

	while read line; do
		host $line 2>/dev/null | grep "has address" | awk '{print $4 "\t\t" $1}'
	done < hosts
}

print_links() {
	echo
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo -e "${CYAN}                            Links Found                                         ${NC}"
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo

	while read line; do
		echo $line
	done < links
}

print_hosts() {
	echo
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo -e "${CYAN}                            Hosts Found                                         ${NC}"
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo

	while read line; do
		echo $line
	done < hosts
}

print_results() {
	echo
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo -e "Found: \t" ; wc -l links
	echo -e "\t" ; wc -l hosts
	echo -e "${CYAN}--------------------------------------------------------------------------------${NC}"
	echo
}

main() {
	prerun

	case $ARG1 in
		"-v" | "--version")
			echo "Version: ${VERSION}"
			exit 0
		;;
		
		"-h" | "--help")
			helper
			exit 0
		;;

		"-f" | "--file")
			echo "TODO"
			exit 0
		;;

		*)
			download_page
			parse_html
			print_links
			get_hosts
			print_hosts
			get_live_hosts
			print_results
			cleanup
		;;
	esac
}

main
