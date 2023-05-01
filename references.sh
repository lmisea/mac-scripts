#!/bin/bash
# Script that stores references to files that are not devices.
# The references can be added or removed. Also, is not necessary that
# the file where the reference points to exists.
# Written by LP (Llama Perpetua) - 2023.

usage() {
	echo -e "\033[1m\033[36mUsage:\033[0m\n\t$(basename $0) [OPTION] [OCTAL-MODE] [FILE]..."
}

synopsis() {
	echo -e "\n\033[1m\033[36mSynopsis:\033[0m\n\tScript that stores references to files that are not devices."
	echo -e "\tThe references can be added or removed. Also, is not necessary that"
	echo -e "\tthe file where the reference points to exists."
}

options() {
	echo -e "\n\033[1m\033[36mOptions:\n\t\033[33m-a, --add\033[0m\t\tAdd and store a reference to given files."
	echo -e "\t\033[1m\033[33m-c, --check\033[0m\t\tCheck if given files have a reference."
	echo -e "\t\033[1m\033[33m-d, --delete\033[0m\t\tDelete a reference to given files."
	echo -e "\t\033[1m\033[33m-p, --mod-permissions\033[0m\tChange permisions of given files."
	echo -e "\t\t\t\tBefore file, add new permissions in OCTAL-MODE."
	echo -e "\t\033[1m\033[33m-D, --delete-all\033[0m\tDelete all the references stored."
	echo -e "\t\033[1m\033[33m-r, --list-references\033[0m\tList all references."
	echo -e "\t\033[1m\033[33m-h, --help\033[0m\t\tDisplay this help and exit.\n"
	echo -e "\tOnly ONE option can be set at a time."
	echo -e "\tThere cannot be two or more options passed to the script."
	echo -e "\n\tIf no option is specified, all references will be listed by default."
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

checkIfFileHasReference() {
	echo -e "Checking if \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m has a reference..."
	if [ -f "$HOME/.references" ]; then
		if cat -n $HOME/.references | awk '{print $4}' | grep -wEq "$(realpath -m ${fileName} 2> /dev/null)$"; then
			fileHasReference=true
			lineNumberOfTheReference=$(cat -n $HOME/.references | grep -wE "$(realpath -m ${fileName} 2> /dev/null)$" | awk '{print $1}')
			echo -e "\033[36mYes, \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m \033[36malready has a reference.\033[0m"
		else
			echo -e "\033[31mNo, \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m \033[31mdoesn't have a reference.\033[0m"
		fi
	else
		echo -e "\033[31mNo, it doesn't have a reference. There are no stored references at the moment.\033[0m"
	fi
}

addReference() {
	checkIfFileHasReference &> /dev/null
	if [ "$fileHasReference" = true ]; then
		echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m already has a reference. Skipping." >&2
	else
		if [[ "$(realpath -m ${fileName} 2> /dev/null)" == /dev/* ]]; then
			if ls -l /dev | grep '^[bc]' | awk '{print $10}' | grep -E "$(basename ${fileName})$" &> /dev/null
				then echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m is a device. Skipping." >&2
			else
				referenceCanBeAdded=true
			fi
		else
			referenceCanBeAdded=true
		fi
		if [ "$referenceCanBeAdded" = true ]; then
			echo -e "Adding a reference to \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m..."
			touch $HOME/.references
			reference=$(openssl rand -base64 18)
			until [ "$referenceIsNotRepeated" = true ]; do
				if cat $HOME/.references | awk '{print $1}' | grep -wEq "${reference}$"
					then reference=$(openssl rand -base64 18)
				else
					referenceIsNotRepeated=true
				fi
			done
			echo "${reference} => $(realpath -m ${fileName} 2> /dev/null)" >> $HOME/.references
			echo -e "\033[36mReference added.\033[0m"
		fi
	fi
	unset fileHasReference
	unset lineNumberOfTheReference
}

deleteReference() {
	checkIfFileHasReference &> /dev/null
	if [ "$fileHasReference" = true ]; then
		echo -e "Deleting reference to \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m..."
		if sed -i "${lineNumberOfTheReference}d" $HOME/.references &> /dev/null; then
			echo -e "\033[36mReference deleted.\033[0m"
		else
			echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m an error ocurred while deleting the reference." >&2
			exitCode=1
		fi
	else
		echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m doesn't have a reference to delete." >&2
		exitCode=1
	fi
	unset fileHasReference
	unset lineNumberOfTheReference
}

deleteAllReferences() {
	if [ -f "$HOME/.references" ]; then
		if rm -f $HOME/.references &> /dev/null; then
			echo -e "\033[36mAll the references have been deleted.\033[0m"
		else
			echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m an error ocurred while deleting all the references." >&2 ; exit 1
		fi
	else
		echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m there are no stored references to delete at the moment." >&2
	fi
}

listAllReferences() {
	if [ -f "$HOME/.references" ]; then
		echo -e "\033[1mNumber\t\t\033[33mReference\t\t    \033[36mFile\033[0m"
		cat -n $HOME/.references | awk '{print "\033[1m"$1"\033[0m\033[33m\t"$2"\033[0m \033[1m"$3"\033[0m \033[36m"$4"\033[0m"}'
	else
		echo -e "\033[31mThere are no stored references at the moment.\033[0m"
	fi
}

changeFilePermissions(){
	checkIfFileHasReference &> /dev/null
	if [ "$fileHasReference" = true ]; then
		if [ -f "$(realpath -m ${fileName})" ]; then
			echo "Changing permissions of \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m..."
			if chmod ${newPermissions} ${fileName} &> /dev/null; then
				echo -e "\033[36mPermissions changed.\033[0m"
			else
				echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m an error ocurred while changing permissions." >&2
				exitCode=1
			fi
		else
			echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m doesn't exists." >&2
			echo "Permissions of a non existent file cannot be modified. Skipping." >&2
		fi
	else
		echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m \033[3m\`$(realpath -m ${fileName} 2> /dev/null)\`\033[0m doesn't have a reference. Skipping." >&2
	fi
	unset fileHasReference
	unset lineNumberOfTheReference
}

numOfFlags=0
exitCode=0

while getopts "acdDrph-:" opt; do
	case ${opt} in
		a ) add=true ; ((numOfFlags++)) ;;
		c ) check=true ; ((numOfFlags++)) ;;
		d ) delete=true ; ((numOfFlags++)) ;;
		D ) deleteAll=true ; ((numOfFlags++)) ;;
		r ) listReferences=true ; ((numOfFlags++)) ;;
		p ) changePermissions=true ; ((numOfFlags++)) ;;
		h ) help ; exit 0 ;;
		- ) case "${OPTARG}" in
			add ) add=true ; ((numOfFlags++)) ;;
			check ) check=true ; ((numOfFlags++)) ;;
			delete ) delete=true ; ((numOfFlags++)) ;;
			delete-all ) deleteAll=true ; ((numOfFlags++)) ;;
			list-references ) listReferences=true ; ((numOfFlags++)) ;;
			mod-permissions ) changePermissions=true ; ((numOfFlags++)) ;;
			help ) help ; exit 0 ;;
			* ) echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option: --${OPTARG}" >&2
				echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1 ;;
			esac ;;
		* ) echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1 ;;
	esac
done

if [[ "$*" == *"-- "* ]] || [[ "$*" == *"- "* ]]; then
	echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option. Don't use space specifying an option." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1
fi

if [[ "$*" == "--" ]]; then
	echo -e "\033[1m\033[31m$(basename $0):\033[0m illegal option: --" >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1
fi

if [ $numOfFlags -gt 1 ]; then
	echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m only ONE option can be set at a time." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1
fi

if [ "$deleteAll" = true ]
	then deleteAllReferences
elif [ "$listReferences" = true ] || [ $numOfFlags -eq 0 ]
	then listAllReferences
elif [ $# -eq 1 ]; then
	echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m option requires file(s) as argument." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exitCode=1
fi

until [ $# -lt 2 ]; do
	if [ "$changePermissions" = true ]; then
		newPermissions="$2" ; fileName="$3"
		if [ -z $fileName ]; then
			echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m option requires new OCTAL-MODE permissions and file." >&2
			echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exitCode=1
		else
			if [[ "$newPermissions" =~ ^[0-7]{1,4}$ ]]
				then changeFilePermissions
			else
				echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m specify permissions in 1 up to 4 OCTAL-MODE numbers." >&2
				echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1
			fi
		fi
		shift 2
	else
		fileName="$2"
		if [ "$add" = true ]
			then addReference
		elif [ "$check" = true ]
			then checkIfFileHasReference
		elif [ "$delete" = true ]
			then deleteReference
		fi
		shift
	fi
done

exit ${exitCode}
