#!/bin/bash

# This script is for patching, assuming that the WAR/JAR file is deployed on the server.
# Created by emsi-G
# Usage : ./do-patch-???.sh 20230721

#1) Checks if the script is run with the correct number of arguments (one date argument).
#2) Verifies if the patch folder exists.
#3) Creates a backup folder if it doesn't exist.
#4) Stops the application.
#5) Moves the application directory to the backup folder.
#6) Moves the new version of the JAR file to the application directory.
#7) Unpacks the WAR file. 
#8) Starts the application.
#9) Cleans up the temporary files.

# TG_DT must be YYYYMMDD
TG_DT=$1
B_USER="admin"
C_USER="jenkins"
PRJ_NAME=app_name_v1
WAR_NAME=app_name_v1-prd-1.0.0.war

APP_START=startup.sh
APP_STOP=shutdown.sh
TOMCAT=app_name_server
APP_PATH=/app/${B_USER}/servers/${TOMCAT}/bin

PATCH_DIR=/home/${C_USER}/patch
SRC_DIR=${PATCH_DIR}/${TG_DT}/${PRJ_NAME}
SRC_APP=${SRC_DIR}/${WAR_NAME}

DST_DIR=/app/${B_USER}/api/app-server 
DST_OLD_DIR=/app/${B_USER}/api/app-server-bkup
BACKUP_NAME=`date '+%Y%m%d_%H%M%S'`
BACKUP_DIR=${DST_OLD_DIR}/${BACKUP_NAME}


exec_root(){
        echo -e $1 | sudo -u root /bin/bash
}

exec_app(){
        echo -e $1 | sudo -u ${B_USER} /bin/bash
}

exec_user(){
        echo -e $1 | sudo -u ${C_USER} /bin/bash
}

log(){
        echo "[${PRJ_NAME}] "$1
}

#End Config

log "Authentication Required"

WHO_AM_I=`sudo whoami`
if [ "${WHO_AM_I}" != "root" ]; then
        log "Error: Canceled, failed to acquire root authentication."
        exit -1
fi

if [ "$#" != 1 ]; then
        log "Wrong Parameter"
        log "Example Syntax: ./do-patch-${PRJ_NAME} $(date +%Y%m%d)"
        exit -1
fi

exec_app "ls $SRC_APP > /dev/null 2>&1"

if [ "$?" == 0 ]; then
        log "Found patch folder: ${SRC_APP}"
else
        log "Failed to find patch folder: ${PATCH_DIR}/${TG_DT}"
        exit -1
fi


sleep 2

log "Preparing backup folder"

if [ ! -d "${DST_OLD_DIR}" ]; then
        exec_app "mkdir -p ${DST_OLD_DIR}"
        log "Can't find backup folder, canceled: "${DST_OLD_DIR}
        exit -1;
fi

sleep 1

log "We will PATCH the ${PRJ_NAME} now"

sleep 2

log "Stopping ${TOMCAT} now..."
exec_app "${APP_PATH}/${APP_STOP}"

if [ "$?" != 0 ]; then
        log "The app cannot shutdown, canceled."
        log "Kindly check the app now."
        exit -1
fi

sleep 10

if [ -d "${DST_DIR}" ]; then
        log "Backup folder ${DST_DIR} to ${BACKUP_DIR}"
        exec_app "mkdir -p ${BACKUP_DIR}"
        exec_app "mv ${DST_DIR} ${BACKUP_DIR}"
        exec_app "mkdir -p ${DST_DIR}"
        sleep 1
elif [ ! -d "${DST_DIR}" ]; then
        log "Cannot find the ${DST_DIR}, canceled."
        log "Starting ${TOMCAT} now..."
        exec_app "${APP_PATH}/${APP_START}"
        sleep 5
        exit -1
fi

log "Moving the ${WAR_NAME} to ${DST_DIR}"
exec_root "mv ${SRC_DIR}/* ${DST_DIR}"
exec_root "chown ${B_USER}:${B_USER} -R ${DST_DIR}"
sleep 3

log "Extracting the ${WAR_NAME} now"
exec_app "unzip -q ${DST_DIR}/${WAR_NAME} -d ${DST_DIR}"
sleep 3

log "Starting the ${TOMCAT} now"
exec_app "${APP_PATH}/${APP_START}"
sleep 5

log "Done patching ${PRJ_NAME}"
sleep 1

log "Clearing resources"
exec_user "rm -fr ${SRC_DIR}"

