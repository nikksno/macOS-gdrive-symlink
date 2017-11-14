#!/bin/bash

echo

r=`tput setaf 1`
g=`tput setaf 2`
x=`tput sgr0`
b=`tput bold`

scriptname=`basename "$0"`

if [[ $EUID -ne 0 ]]
then
	echo "${r}${b}This script must be run as root. Run it as:${x}"
	echo
	echo "sudo bash create-drive-symlink"
	echo
	exit
fi

echo "${g}${b}Initiating $scriptname...${x}"
echo


echo "${b}These are the current users in this system:${x}"
echo
dscacheutil -q user | grep -A 3 -B 2 -e uid:\ 5'[0-9][0-9]'
echo
sleep 1

defined=n
until [ $defined = "y" ]
do
	exists=n
	until [ $exists = "y" ]
	do
		seluser=""
		until [ ! $seluser = "" ]
		do
			read -p "${b}Now specify the user to apply the Google Drive symlinks to: ${x}" seluser
			echo
		done
		if [ -d /Users/$seluser ]
		then
			exists=y
		else
			echo "${r}${b}The specified user does not exists. Please retry...${x}"
			echo
			exists=n
		fi
	done
	valid=n
	until [ $valid = "y" ]
	do
		read -n 1 -p "${b}Is | $seluser | correct? (Y/n/e[xit]) ${x}" answer;
		case $answer in
		"")
			echo
			valid=y
			defined=y
			;;
		y)
			echo -e "\n"
			valid=y
			defined=y
			;;
		n)
			echo -e "\n"
			echo "${b}Ok, then please try again...${x}"
			echo
			valid=y
			defined=n
			;;
		e)
			echo -e "\n"
			echo "${b}Exiting...${x}"
			echo
			exit
			;;
		*)
			echo -e "\n"
			echo "${r}${b}Invalid option. Retry...${x}"
			echo
			valid=n
		defined=n
		;;
		esac
	done
done

echo "${b}Ok, selected user | $seluser |${x}"
echo



if [ ! -d "$seluser/Google Drive" ]
then
	echo "${r}${b}Google Drive doesn't seem to be installed and/or set up for user $seluser${x}"
	echo
	echo "${b}Please install and set up Google Drive for that user [no need for it to finish syncing all the way] and then re-run this script.${x}"
	echo
        echo "${b}Exiting...${x}"
        echo
        exit
fi



echo "${b}The user directories we'll be locating shortly are the Desktop, Documents, Downloads, etc... folders you find in any macOS user account.${x}"
echo

read -p "${b}Do the user directories already precisely exist in $seluser's Google Drive [i.e. from a manual attempt at achieving this script's function]? (Y/n): ${x}" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
	moveuserdirs=n
	read -p "${b}Ok. Are these directories inside a Google Drive subdirectory [i.e. | /Users/$seluser/Google Drive/${r}SUBDIRECTORY${x}${b}/Documents/ | ]? (Y/n): ${x}" -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]
	then
		defined=n
		until [ $defined = "y" ]
		do
			exists=n
			until [ $exists = "y" ]
			do
				gdsubdir=""
				until [ ! $gdsubdir = "" ]
				do
					echo "${b}Ok. Now we need to locate the Google Drive subdirectory inside of which the user directories are: ${x}"
					echo
					echo "${b}Only specify the subdirectory name, no paths.${x}"
					echo
					echo "${b}[i.e. specify | SUBDIRECTORY | in case of the subdirectory being | /Users/$seluser/Google Drive/${r}SUBDIRECTORY${x}${b}/Documents/ |.${x}"
					echo
					read -p "${b}Now specify the name of Google Drive subdirectory inside of which the user directories are: ${x}" gdsubdir
					echo
				done
				if [ -d $gdsubdir ]
				then
					exists=y
				else
					echo "${r}${b}The specified directory does not exists. Please retry...${x}"
					echo
					exists=n
				fi
			done
			valid=n
			until [ $valid = "y" ]
			do
				read -n 1 -p "${b}Is | $gdsubdir | correct? (Y/n/e[xit]) ${x}" answer;
				case $answer in
				"")
					echo
					valid=y
					defined=y
					;;
				y)
					echo -e "\n"
					valid=y
					defined=y
					;;
				n)
					echo -e "\n"
					echo "${b}Ok, then please try again...${x}"
					echo
					valid=y
					defined=n
					;;
				e)
					echo -e "\n"
					echo "${b}Exiting...${x}"
					echo
					exit
					;;
				*)
					echo -e "\n"
					echo "${r}${b}Invalid option. Retry...${x}"
					echo
					valid=n
					defined=n
					;;
				esac
			done
		done
	fi
else
	moveuserdirs=y
	echo "${b}Ok, no problem. We'll be moving them automatically to Google Drive's root folder [i.e. /Users/$seluser/Google Drive/${r}Desktop/${x}${b} ]: ${x}"
	echo
fi



localbasedir="/Users/$seluser" # No trailing slash
gdbasedir="/Users/$seluser/Google Drive/$gdsubdir" # No trailing slash

declare -a dirarray=(
	"Applications"
	"Desktop"
	"Documents"
	"Downloads"
	"Movies"
	"Music"
	"Pictures"
	"Public"
                )

for i in "${dirarray[@]}"
do
	thislocaldir=$localbasedir/$i
	thisgddir=$gdbasedir/$i

	if [[ -L "$thislocaldir" && -d "$thislocaldir" ]]
	then
		echo "${r}${b}$thislocaldir appears to already be a symlink to another directory.${x}"
		echo
		echo "${b}This means you've likely already run this script, at least partially.${x}"
		echo
		echo "${b}Skipping this directory...${x}"
		echo
	fi

	if [ $moveuserdirs = "y" ]
	then

		if [ -d $thisgddir ]
		then
			echo "${r}${b}The directory $thisgddir already exists on Google Drive.${x}"
			echo
			echo "${b}Re-run the script either after merging $thislocaldir with $thisgddir or selecting a different location on Google Drive${x}."
			echo
			echo "${b}Exiting...${x}"
			echo
			exit
                fi

		echo mv $thislocaldir $thisgddir #debug
                echo "${g}${b}Moved $thislocaldir to $thisgddir.${x}"
                echo

        else

                if [ ! -z "$(ls $thislocaldir)" ]
                then

			echo "${r}${b}The directory $thisgddir does not appear to be empty.${x}"
			echo
			echo "${b}Having selected that User Directories already exist in Drive, running this script on this directory would all of its contents to be deleted.${x}."
			echo
                        echo "${b}Re-run the script either after merging $thislocaldir with $thisgddir or otherwise after having disposed of all items in $thislocaldir.${x}"
                        echo
                        echo "${b}Exiting...${x}"
			echo
			exit
                fi

                echo rm -r $thislocaldir && ln -s $thisgddir $thislocaldir #debug
                echo "${g}${b}Deleted $thislocaldir and created symlink $thislocaldir pointing to $thisgddir.${x}"
                echo

        fi

done

echo "${b}All done!${x}"
echo
