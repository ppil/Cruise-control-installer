#!/bin/sh
# Cruise-control installer
# Written by Peter Pilarski for EMUSec competitions
version="1.3"

usage() {
	echo "Cruise-control installer v$version

-f <FILE>
	File containing package list. (Default: ./toolbox)
-p <PM command>
	Specify a different install command to use.
	E.g.: -p \"/usr/bin/apt-get -y install\"
-r
	Remove specified packages instead of installing.
-s <package>
	Add/remove a single package.
-y
	Yes, I'm sure. Don't prompt for confirmation.
-h
	For when you miss reading this.
"
}
parseOpts() {
	while getopts :hHyYrRf:F:p:P:s:S: opt; do
		case $opt in
			h|H)# Help
				usage
				exit 0
				;;
			f|F)# File
				pkgList="$OPTARG"
				;;
			p|P)# Specified PM
				pmInstall="$OPTARG"
				unset -v rmPkg
				;;
			r|R)# Remove
				[ "$pmInstall" ] || rmPkg=1
				;;
			s|S)# Single package
				pkgList="$OPTARG"
				single=1
				;;
			y|Y)# Yup, no prompt
				srsly='Y'
				;;
			\?)# Unknown/invalid
				echo "Invalid option: -$OPTARG"
				usage
				exit 1
				;;
			:)# Missing arg
				echo "An argument must be specified for -$OPTARG"
				usage
				exit 1
				;;
		esac
	done
}
# Find package managers so we can put this shit on everything
getPM() {
	# Debian-based
	if [ -e "$(which apt-get 2>/dev/null)" ]; then
		pmInstall="$(which apt-get) -y install"
		pmRemove="$(which apt-get) -y remove"
	elif [ -e "$(which aptitude 2>/dev/null)" ]; then
		pmInstall="$(which aptitude) -y install"
		pmRemove="$(which aptitude) -y remove"
	# Redhat-based
	elif [ -e "$(which yum 2>/dev/null)" ]; then
		pmInstall="$(which yum) -y install"
		pmRemove="$(which yum) -y remove"
	# SUSE (if apt-get/aptitude not available)
	elif [ -e "$(which zypper 2>/dev/null)" ]; then
		pmInstall="$(which zypper) --non-interactive install"
		pmRemove="$(which zypper) --non-interactive remove"
	# Arch
	elif [ -e "$(which pacman 2>/dev/null)" ]; then
		pmInstall="$(which pacman) --noconfirm -Sy"
		pmRemove="$(which pacman) --noconfirm -R"
	# Gentoo
	elif [ -e "$(which emerge 2>/dev/null)" ]; then
		pmInstall="$(which emerge)"
		pmRemove="$(which emerge) -C"
	# Solaris
	elif [ -e "$(which pkg 2>/dev/null)" ] && [ "$(uname)" = "SunOS" ]; then
		pmInstall="$(which pkg) install --accept"
		pmRemove="$(which pkg) uninstall"
	# FreeBSD
	elif [ -e "$(which pkg 2>/dev/null)" ]; then
		pmInstall="$(which pkg) install -y"
		pmRemove="$(which pkg) delete -y"
	# OpenBSD
	elif [ -e "$(which pkg_add 2>/dev/null)" ]; then
		pmInstall="$(which pkg_add)"
		pmRemove="$(which pkg_delete)"
		export PKG_PATH=ftp://mirrors.mit.edu/pub/OpenBSD/$(uname -r)/packages/$(arch -s)/:${PKG_PATH}
	else
		echo "No package manager found! Consider using -p"
		exit 1
	fi
}
installShit() {
	if [ "$rmPkg" ]; then
		pmCmd="$pmRemove"
	else
		pmCmd="$pmInstall"
	fi
	printf "\nAdding/removing packages using '%s'\n\n" "$pmCmd"
	if [ ! "$srsly" ]; then # Prompt only if -y not given
		echo "Are you sure you want to do this? (Y/N):" 
		read srsly
	fi
	if [ "$srsly" = "Y" ] || [ "$srsly" = "y" ]; then
		if [ "$single" ]; then
			$pmCmd "$pkgList" # e.g. apt-get -y install $pkgList
			return
		fi
		while read -r line; do
			if [ -e "$(which "$line" 2>/dev/null)" ]; then
				echo "$line is already installed, skipping."
			else
				$pmCmd "$line" # e.g. apt-get -y install $line
			fi
		done < "$pkgList"
	fi
}

pkgList="./toolbox" # Default list file
parseOpts "$@" # Parse argv
if [ "$(whoami)" != "root" ]; then
	echo "This script needs to be run as root."
	exit 1
fi
[ "$pmInstall" ] || getPM # Find installed package manager
installShit # Do work
