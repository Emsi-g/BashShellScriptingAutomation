#!/bin/bash

# This script is for rollback the tomcat server API
# Created by Emsi-g
# Usage : ./do-rollback-api.sh
# DON'T RUN IT WITH SUDO


PATCH_SUBJECT="Rollback CheckoutAPI"
PATH_OLD_DIR=/home/user/appname/api_old		#api_old is where the previous version store
PATH_DIR=/home/user/appname 			#appname is where the artifacts (WEB-INF, META-INF, etc.)  are being stored
B_USER="user"					#username
API="api"

#Function that will execute the bash using USER
run_app(){
        echo -e $1 | sudo -u ${B_USER} /bin/bash
}

#Function that will execute the bash using ROOT
run_root(){
        echo -e $1 | sudo -u root /bin/bash
}

#Function for echo
slog(){
	echo "[${PATCH_SUBJECT}] $1"
}

#Function for choices
ask_yes_or_no(){
	read -p "[${PATCH_SUBJECT}] $1 ([y]es or [N]o): "
	case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
	y|yes) echo "yes" ;;
	*) echo "no" ;;
	esac
}

#For checking if you are part of sudoers
WHO_AM_I=`sudo whoami`
if [ "${WHO_AM_I}" != "root" ]; 
then
	slog "Error: Canceled, Failed to acquire root auth."
	exit -1
fi

slog "Finding the file..."
sleep 1

#It will check the files for the previous version of artifacts
ls ${PATH_OLD_DIR}/* &> /dev/null

if [ `echo $?` -ne 0 ]; 
then
	slog "No found file."
	exit -1
fi

#It will get the folder name (For versioning) of the previous artifacts
for files in `ls -r ${PATH_OLD_DIR}`
do
	OLD_DIR=$(basename "$files") 
	if [ "yes" == $(ask_yes_or_no "File found $(echo $OLD_DIR). Is this the directory?") ]
	then 
		break
	else
		slog "Next."
		if [ "${OLD_DIR}" == "`ls ${PATH_OLD_DIR}| head -1`" ]
		then
			slog "No source file found. Will exit now."
			exit 0
		fi
		continue
	fi
done

slog "File found $OLD_DIR. We will now proceed to ROLLBACK."

#Warning before proceeding.
if [[ "no" == $(ask_yes_or_no "Are you sure to do rollback?") || \
	  "no" == $(ask_yes_or_no "Are you *really* sure?") ]]
then
	slog "Skipped."
	exit 0
fi

slog "Tomcat shutdown..."
run_app "/home/${B_USER}/webserver/${API}/bin/shutdown.sh"	#The path of your tomcat server
	if [ `echo $?` -ne 0 ]; 
	then
		slog "Tomcat Cannot Shutdown. Rollback cancelled. Exiting now..."
		exit -1
	fi

sleep 5

slog "Remove ${PATH_DIR}/${API}"
run_app "rm -rf ${PATH_DIR}/${API}"				#The path of your current artifacts (Latest version)
	if [ `echo $?` -ne 0 ]; 
	then
		slog "Current API dir, cannot delete. Rollback cancelled. Exiting now..."
		slog "Tomcat startup..."
		run_app "/home/${B_USER}/webserver/${API}/bin/startup.sh"
		exit -1
	fi

slog "Rollback now..."
run_app "mv -f ${PATH_OLD_DIR}/${OLD_DIR}/* ${PATH_DIR}" 	#The path of your old artifacts (Previous version)
	if [ `echo $?` -ne 0 ]; 
	then
		slog "Cannot move. Kindly check the ${PATH_DIR}/${API}. Rollback cancelled. Exiting now..."
		exit -1
	fi

sleep 5

slog "Tomcat startup..."
run_app "/home/${B_USER}/webserver/${API}/bin/startup.sh"	#The path of your tomcat server
	if [ `echo $?` -ne 0 ]; 
	then
		slog "Rollback done but cannot start tomcat. Kindly check the tomcat API bin."
		exit -1
	fi

slog "Clearing old source file..."
run_app "rmdir ${PATH_OLD_DIR}/${OLD_DIR}"

slog "Patch finished...."