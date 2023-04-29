#!/bin/bash
# Script that manages kernel modules. Allows to check if a module is currently
# being loaded by the kernel, load one or unload it. An error is return if the
# kernel cannot find the module specified.
# Written by LP (Llama Perpetua) - 2023.

usage() {
	echo -e "\033[1m\033[36mUsage:\033[0m\n\t$(basename $0) [OPTION] modulename"
}

synopsis() {
	echo -e "\n\033[1m\033[36mSynopsis:\033[0m\n\tScript that manages kernel modules. Allows to check if a module is currently"
	echo -e "\tbeing loaded by the kernel, load one or unload it. An error is return if the"
	echo -e "\tkernel cannot find the module specified."
}

options() {
	echo -e "\n\033[1m\033[36mOptions:\n\t\033[33m-a, --activate\033[0m\t\tLoad a module that is not loaded."
	echo -e "\t\t\t\tCannot be used with -d option."
	echo -e "\t\033[1m\033[33m-d, --deactivate\033[0m\tUnload a module that is loaded."
	echo -e "\t\t\t\tCannot be used with -a option."
	echo -e "\t\033[1m\033[33m-h, --help\033[0m\t\tDisplay this help and exit."
	echo -e "\n\tIf no option is set, checks if a module is loaded or not by"
	echo -e "\tthe kernel."
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

searchModule() {
	echo -e "Searching \033[3m${moduleName}\033[0m..."
	if modinfo ${moduleName} &> /dev/null ; then
		if lsmod | tail -n +2 | cut -d ' ' -f 1 | grep ^"${moduleName}"$ &> /dev/null
			then
				echo -e "\033[36mModule \033[3m${moduleName}\033[0m \033[36mis currently loaded.\033[0m"
				activated=true
		else
			echo -e "\033[31mModule \033[3m${moduleName}\033[0m \033[31mis not currently loaded.\033[0m"
			deactivated=true
		fi
	else
		echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m module \033[3m${moduleName}\033[0m cannot be located by the kernel." >&2
		exitCode=1
		notAModule=true
	fi
}

activateModule() {
	searchModule &> /dev/null
	if [ "$notAModule" = true ]; then
		echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m module \033[3m${moduleName}\033[0m cannot be located by the kernel." >&2
		exitCode=1
	elif [ "$deactivated" = true ] ; then
		echo -e "Activating \033[3m${moduleName}\033[0m..."
		if sudo modprobe "${moduleName}" &> /dev/null; then
			echo -e "\033[36mModule \033[3m${moduleName}\033[0m \033[36mis now activated.\033[0m"
		else
			echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m an error ocurred while activating the module." >&2
			exitCode=1
		fi
	else
		echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m module \033[3m${moduleName}\033[0m is already activated. Skiping." >&2
	fi
	unset activated
	unset deactivated
	unset notAModule
}

deactivateModule() {
	searchModule &> /dev/null
	if [ "$notAModule" = true ]; then
		echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m module \033[3m${moduleName}\033[0m cannot be located by the kernel." >&2
		exitCode=1
	elif [ "$activated" = true ] ; then
		echo -e "Deactivating \033[3m${moduleName}\033[0m..."
		if sudo modprobe -r "${moduleName}" &> /dev/null; then
			echo -e "\033[36mModule \033[3m${moduleName}\033[0m \033[36mis now deactivated.\033[0m"
		else
			echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m an error ocurred while deactivating the module." >&2
			exitCode=1
		fi
	else
		echo -e "\033[1m\033[33m$(basename $0): Warning:\033[0m module \033[3m${moduleName}\033[0m is already deactivated. Skiping." >&2
	fi
	unset activated
	unset deactivated
	unset notAModule
}

while getopts "adh-:" opt; do
	case ${opt} in
		a ) activate=true ;;
		d ) deactivate=true ;;
		h ) help ; exit 0 ;;
		- ) case "${OPTARG}" in
			activate ) activate=true ;;
			deactivate ) deactivate=true ;;
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

if [ $OPTIND -eq 1 ]
	then noFlags=true;
else
	shift
fi

if [ "$activate" = true ] && [ "$deactivate" = true ]; then
	echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m flags -a and -b cannot be used at the same time." >&2
	echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1;
fi

if [ $# -eq 0 ]; then
		echo -e "\033[1m\033[31m$(basename $0): Error:\033[0m module name is required." >&2
		echo -e "For more information try \033[36m'$(basename $0) --help'\033[0m" >&2 ; exit 1;
fi

exitCode=0

until [ $# -lt 1 ]; do
	moduleName="$1"
	if [ "$activate" = true ]
		then activateModule
	elif [ "$deactivate" = true ]
		then deactivateModule
	elif [ "$noFlags" = true ]
		then searchModule
	fi
	shift
done

exit ${exitCode}
