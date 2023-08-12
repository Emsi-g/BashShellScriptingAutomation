#!/bin/bash

# This script is created by Emsi-G
# This should run in a bastion server, and ssh to your private servers using a private IP Address.
# This will get the disk usage, free ram, and check if the servers are running.

PATH_TO_YOUR_PEM=/home/user/keys #Path to your keys, make sure to remove the passphrase key
AS_APP_PATH_TO_YOUR_WEBSERVER=/home/admin/servers/api #Path to your webserver
PORTWeb="21322" #SSH Port, 22 is the default
PORTApp="21323" #SSH Port, 22 is the default
PIPWeb='10.10.22.101' #Private IP of your webserver
PIPApp='10.10.22.102' #Private IP of your appserver
USER="user"
current_date=$(date)

AS_APP(){
        sudo ssh -i ${PATH_TO_YOUR_PEM}/AS_APP_SERVER.pem -p ${PORTApp} ${USER}@${PIPApp} $1
}

WEB_APP(){
        sudo ssh -i ${PATH_TO_YOUR_PEM}/AS_WEB_SERVER.pem -p ${PORTWeb} ${USER}@${PIPWeb} $1
}

ASAPP=$(AS_APP "ps -ef | grep ${AS_APP_PATH_TO_YOUR_WEBSERVER} | wc -l")
ASWEB=$(WEB_APP "systemctl status nginx | grep 'running' | wc -l")

#Edit text and add color
ACTIVE="\e[32mACTIVE\e[0m" # GREEN
NOT_ACTIVE="\e[31mNOT ACTIVE\e[0m" # RED

IFELSE() {
        if [[ $1 -ge 3 ]]
         then
                 echo -e "\t$2 \t\t\t\t - [ ${ACTIVE} ]";

         else
                 echo -e "\t$2 \t\t\t\t - [ ${NOT_ACTIVE} ]";
        fi
}

IFELSE2() {
        if [[ $1 -ge 1 ]]
         then
                 echo -e "\t$2 \t\t\t\t\t - [ ${ACTIVE} ]";

         else
                 echo -e "\t$2 \t\t\t\t\t - [ ${NOT_ACTIVE} ]";
        fi
}

#End Config

######################################################################


echo -e "\n";
echo -e "=================== [ START ] SERVERS STATUS =================== \n";
echo -e "\t\t$current_date"
echo
echo "##### WEB SERVER #####"
WEB_APP "df --output=target,pcent / /logs30;free | awk '/Mem/{printf(\"FREE RAM: %.0f%\n\"), (\$7/\$2)*100}'"
echo

echo "##### APP SERVER #####"
AS_APP "df --output=target,pcent / /logs30;free | awk '/Mem/{printf(\"FREE RAM: %.0f%\n\"), (\$7/\$2)*100}'"
echo
echo "==============================================================="
echo
echo -e "## AS APP SERVER ##"
IFELSE $ASAPP "API SERVER"

echo
echo -e "\n## AS WEB SERVER ##"
IFELSE2 $ASWEB "NGINX"

echo -e "\n";
echo -e "================= [ END ] WEBSERVER STATUS ==================== \n";
