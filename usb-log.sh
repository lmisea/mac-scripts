#!/bin/bash
# Script for tracking the USB connections and diconnections history.
# The output is displayed as a nice formated table.
# The output can be saved to a log file.
# Written by LP (Llama Perpetua) - 2023.

# Please run install-usb-log.sh before running this script.

usage() {
	echo -e "\033[1m\033[36mUsage:\033[0m\n\t$(basename $0) [OPTIONS...]"
}

synopsis() {
	echo -e "\n\033[1m\033[36mSynopsis:\033[0m\n\tScript for tracking the USB connections and diconnections history."
	echo -e "\tThe output is displayed as a nice formated table."
}

options() {
	echo -e "\n\033[1m\033[36mOptions:\n\t\033[33m-c, --connections\033[0m\tOutput only usb connections."
	echo -e "\t\tCannot be used with -d option.\n"
	echo -e "\t\033[1m\033[33m-d, --disconnections\033[0m\tOutput only usb disconnections."
	echo -e "\t\tCannot be used with -c option.\n"
	echo -e "\t\033[1m\033[33m-f, --save-to-file\033[0m\tSave the output to a log file."
	echo -e "\t\tFile generated as '/home/luismi/usb-log/<date>.log'\n"
	echo -e "\t\033[1m\033[33m-h, --help\033[0m\t\tDisplay this help and exit."
	echo -e "\n\tIf options -c and -d are not used, output both usb connections\n\tand disconnections."
}

author() {
	echo -e "\n\033[1m\033[36mAuthor:\033[0m\n\tWritten by \033[1mLP\033[0m (Llama Perpetua)."
}

help() {
	usage
	synopsis
	options
	author
}

echoOutputSavedToFile() {
	echo -e "\033[1m\033[32mOutput saved to file:\033[0m $outputFile"
}

collectOnlyConnections() {
	echo "Collecting only connections..."
	# Check if there are any USB connections
	if [ $(sudo dmesg | grep -i "new usb device found" | grep -oE "usb [0-6]-[0-5]:" | wc -l) -eq 0 ]
		then echo "No USB connections have been found."
	# If there are USB connections, collect them
	else
		# Ask for sudo password before printing the table
		sudo -v
		echo -e "\033[1m-------------------------------------" >  $outputFile
		echo "| Port |    Date/Time Connection    |" >> $outputFile
		echo -e "-------------------------------------\033[0m" >> $outputFile
		sudo dmesg -T | grep -i "new usb device found" | grep -E "usb [0-6]-[0-5]:" | while read -r line
		do
			connectionTime=$(echo "$line" | awk '{print ""$1" "$2" "$3" "$4" "$5""}' | cut -d "]" -f 1 | cut -d "[" -f 2)
			usbPort=$(echo -n "$line" | grep -oE "usb [0-6]-[0-5]:" | grep -o "[0-6]-[0-5]")
			echo -e "| \033[1m\033[34m$usbPort\033[0m  |  $connectionTime  |" >> $outputFile
		done
		echo "-------------------------------------" >> $outputFile
		if [ "$saveToFile" = true ]
			then echoOutputSavedToFile
		fi
	fi
}

collectOnlyDisconnections() {
	echo "Collecting only disconnections..."
	# Check if there are any USB disconnections
	if [ $(sudo dmesg | grep -i "usb disconnect" | grep -oE "usb [0-6]-[0-5]:" | wc -l) -eq 0 ]
		then echo "No USB disconnections have been found."
	# If there are USB disconnections, collect them
	else
		# Ask for sudo password before printing the table
		sudo -v
		echo -e "\033[1m--------------------------------------" >  $outputFile
		echo "| Port |   Date/Time Disconnection   |" >> $outputFile
		echo -e "--------------------------------------\033[0m" >> $outputFile
		sudo dmesg -T | grep -i "usb disconnect" | grep -E "usb [0-6]-[0-5]:" | while read -r line
		do
			disconnectionTime=$(echo "$line" | awk '{print ""$1" "$2" "$3" "$4" "$5""}' | cut -d "]" -f 1 | cut -d "[" -f 2)
			usbPort=$(echo -n "$line" | grep -oE "usb [0-6]-[0-5]:" | grep -o "[0-6]-[0-5]")
			echo -e "| \033[1m\033[34m$usbPort\033[0m  |  $disconnectionTime   |" >> $outputFile
		done
		echo "--------------------------------------" >> $outputFile
		if [ "$saveToFile" = true ]
			then echoOutputSavedToFile
		fi
	fi
}

collectAll() {
	echo "Collecting both connections and disconnections..."
	# Ask for sudo password before printing the table
	sudo -v
	echo -e "\033[1m--------------------------------------------------------------------" >  $outputFile
	echo "| Port |    Date/Time Connection     |   Date/Time Disconnection   |" >> $outputFile
	echo -e "--------------------------------------------------------------------\033[0m" >> $outputFile
	myFile=$(mktemp "usb.XXXXXX" --tmpdir=/run/user/1000)
	linesAlreadyDisplayed=()
	sudo dmesg -T | grep -E "usb [0-6]-[0-5]:" | grep -i 'new usb device found\|usb disconnect' > $myFile
	cat -n $myFile | while read -r line
	do
		lineNumber=$(echo "$line" | awk '{print $1}')
		if [[ " ${linesAlreadyDisplayed[*]} " =~ " ${lineNumber} " ]]
			then continue
		fi
		linesAlreadyDisplayed+=("$lineNumber")
		usbPort=$(echo -n "$line" | grep -oE "usb [0-6]-[0-5]:" | grep -oE "[0-6]-[0-5]")

		# Check if line is a connection or disconnection
		if echo "$line" | grep -i "new usb device found" &> /dev/null
			# Line is a connection
			then
			connectionTime=$(echo "$line" | awk '{print ""$2" "$3" "$4" "$5" "$6""}' | cut -d "]" -f 1 | cut -d "[" -f 2)
			sed -i "${lineNumber}s/.*/     ${lineNumber}  ------/" $myFile
			if cat $myFile | grep -i "usb disconnect" | grep -i "$usbPort" &> /dev/null
				then
				disconnectionLine=$(cat -n $myFile | grep -i "usb disconnect" | grep -i "$usbPort" | head -1)
				disconnectionTime=$(echo "$disconnectionLine" | awk '{print ""$2" "$3" "$4" "$5" "$6""}' | cut -d "]" -f 1 | cut -d "[" -f 2)

				disconnectionLineNumber=$(echo "$disconnectionLine" | awk '{print $1}')
				linesAlreadyDisplayed+=("$disconnectionLineNumber")
				sed -i "${disconnectionLineNumber}s/.*/     ${disconnectionLineNumber}  ------/" $myFile &> /dev/null
			else
				disconnectionTime="    Still connected     "
			fi

		# Line is a disconnection
		else
			disconnectionTime=$(echo "$line" | awk '{print ""$2" "$3" "$4" "$5" "$6""}' | cut -d "]" -f 1 | cut -d "[" -f 2)
			connectionTime="           ---           "
			sed -i "${lineNumber}s/.*/     ${lineNumber}  ------/" $myFile
		fi
		echo -e "| \033[1m\033[34m$usbPort\033[0m  |  $connectionTime   |  $disconnectionTime   |" >> $outputFile
	done
	echo "--------------------------------------------------------------------" >> $outputFile
	if [ "$saveToFile" = true ]
		then echoOutputSavedToFile
	fi
	rm $myFile
}

while getopts "cdlhf-:" opt; do
	case ${opt} in
		f ) saveToFile=true ;;
		c ) onlyConnections=true ;;
		d ) onlyDisconnections=true ;;
		h ) help ; exit 0 ;;
		- ) case "${OPTARG}" in
			save-to-file ) saveToFile=true ;;
			connections ) onlyConnections=true ;;
			disconnections ) onlyDisconnections=true ;;
			help ) help ; exit 0 ;;
			* ) echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option: --${OPTARG}" >&2
				echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1 ;;
			esac ;;
		* ) echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1 ;;
	esac
done

if [[ "$*" == *"-- "* ]] || [[ "$*" == *"- "* ]]
	then echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option. Don't use space specifying an option." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1;
fi

if [[ "$*" == "--" ]]
	then echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option: --" >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1;
fi

exitCode=0

if [ "$saveToFile" = true ]
	# Check if directory exists, if not create it
	then if [ ! -d "/home/luismi/usb-log" ]
		then mkdir /home/luismi/usb-log
	fi
	outputFile=/home/luismi/usb-log/$(date +"%Y-%m-%d_%H-%M-%S").log
	else outputFile=/dev/stdout
fi

if [ "$onlyConnections" = true ] && [ "$onlyDisconnections" = true ]; then
	echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m flags -c and -d cannot be used at the same time." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1;
elif [ "$onlyConnections" = true ]
	then collectOnlyConnections
elif [ "$onlyDisconnections" = true ]
	then collectOnlyDisconnections
else
	collectAll
fi

exit ${exitCode}
