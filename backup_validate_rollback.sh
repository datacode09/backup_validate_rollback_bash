#!/bin/bash

############### Configuraton ###################

# By default, same path as script, file log.txt
LOG_FILE="$(dirname $0)/log.txt"

# Patch where backup folders will be stored
BACKUPS_PATH="/tmp/backups"

################################################

# Log colors
COLOR_RESET='\033[0m'
CYAN='\033[0;36m'
RED='\033[0;31m'

function log()
{
    DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${CYAN}${DATETIME}${COLOR_RESET} - $1"

    echo "${DATETIME} - $1" >> $LOG_FILE
}

function logError()
{
    DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${RED}${DATETIME}${COLOR_RESET} - $1"
    echo "${DATETIME} - ERROR: $1" >> $LOG_FILE
}


function validate()
{
    diff <(find $1 -type f -exec md5sum {} + | sort -k 2 | cut -f1 -d" ") <(find $2 -type f -exec md5sum {} + | sort -k 2 | cut -f1 -d" ") &> /dev/null
    echo $?
}

[ $# -ne 1 -a $# -ne 2 ] && echo "Usage: backup_validate_rollback.sh [-r] <FOLDER>" && exit -1
[ $# -eq 2 -a $1 != "-r" ] && echo "Usage: backup_validate_rollback.sh [-r] <FOLDER>" && exit -1

ROLLBACK=0
if [ $# -eq 2 ]
then
    ROLLBACK=1
    FOLDER=$2
else
    FOLDER=$1
fi
BACKUP_FOLDER="$BACKUPS_PATH/$(basename $FOLDER)_backup"
[ ! -d $FOLDER ] && logError "[$FOLDER] Source folder does not exist. Quitting" && exit -2

#### Rollback parameter included
if [ $ROLLBACK -eq 1 ]
then
    [ ! -d $BACKUP_FOLDER ] && log "[$FOLDER] Backup folder ($BACKUP_FOLDER) does not exist. No rollback needed" && exit 0

    ERROR=$(rm -rf $BACKUP_FOLDER 2>&1)
    [ $? -ne 0 ] && logError "[$FOLDER] Error performing rollback ($ERROR)" && exit -4
    log "[$FOLDER] Rollback finished"
    exit 0
fi

#### Rollback parameter NOT included
if [ -d $BACKUP_FOLDER ]
then
    log "[$FOLDER] Backup folder ($BACKUP_FOLDER) already existed"
else
    log "[$FOLDER] Backup folder ($BACKUP_FOLDER) does not exist. Creating it"
    ERROR=$(mkdir -p $BACKUP_FOLDER 2>&1)
    [ $? -ne 0 ] && logError "[$FOLDER] Error creating backup folder ($ERROR)" && exit -3

    log "[$FOLDER] Copying contents to backup folder"
    ERROR=$(cp -pR $FOLDER/* $BACKUP_FOLDER/ 2>&1)
    [ $? -ne 0 ] && logError "[$FOLDER] Error copying contents to backup folder ($ERROR)" && exit -4

fi

#### Validation (and rollback if not passed)
if [ $(validate $FOLDER $BACKUP_FOLDER) -eq 0 ]
then
    log "[$FOLDER] Copy validation was succesful"
else
    log "[$FOLDER] Copy validation found errors"
    ERROR=$(rm -rf $BACKUP_FOLDER 2>&1)
    [ $? -ne 0 ] && logError "[$FOLDER] Error performing rollback ($ERROR)" && exit -4
    log "[$FOLDER] Rollback finished"
    exit 0
fi
