#!/bin/bash

# Define usage message
function usage {
  echo "Usage: $0 [-r] <FOLDER>"
  exit 1
}

# Parse command line arguments
if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
  usage
fi

rollback=false
while getopts ":r" opt; do
  case ${opt} in
    r )
      rollback=true
      ;;
    \? )
      usage
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$1" ]; then
  usage
fi

# Check if input folder exists
if [ ! -d "$1" ]; then
  echo "Error: $1 is not a valid directory"
  exit 1
fi

# Define backup folder name
timestamp=$(date +%Y%m%d%H%M%S)
backup_folder="${1}_backup_${timestamp}"

# Define log file directory
log_dir="$(dirname "$0")/logs"
mkdir -p "$log_dir"
log_file="${log_dir}/backup_validate_rollback_${timestamp}.log"

# Define function to log messages to log file
function log {
  echo "$(date +%Y-%m-%d_%H:%M:%S) $1" >> "$log_file"
}

# Define function to calculate md5sum for a directory
function calculate_md5sum {
  find "$1" -type f -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{print $1}'
}

# Define function to backup a directory
function backup_directory {
  if [ -d "$backup_folder" ]; then
    echo "Error: $backup_folder already exists"
    exit 1
  fi
  cp -r "$1" "$backup_folder"
  if [ $? -eq 0 ]; then
    log "Backup of $1 to $backup_folder successful"
    original_md5=$(calculate_md5sum "$1")
    backup_md5=$(calculate_md5sum "$backup_folder")
    if [ "$original_md5" == "$backup_md5" ]; then
      log "Checksum validation of backup successful"
      exit 0
    else
      log "Error: checksum validation of backup failed"
      exit 1
    fi
  else
    log "Error: backup of $1 to $backup_folder failed"
    exit 1
  fi
}

# Define function to rollback a directory
function rollback_directory {
  if [[ ! "$1" =~ .*_backup_[0-9]{14} ]]; then
    echo "Error: $1 is not a valid backup folder name"
    exit 1
  fi
  target_folder="$(echo "$1" | sed -e 's/_backup_[0-9]\{14\}//')"
  if [ -d "$target_folder" ]; then
    echo "Error: $target_folder already exists"
    exit 1
  fi
  mv "$1" "$target_folder"
  if [ $? -eq 0 ]; then
    log "Rollback of $1 to $target_folder successful"
    original_md5=$(calculate_md5sum "$target_folder")
    backup_md5=$(calculate_md5sum "$1")
    if [ "$original_md5" == "$backup_md5" ]; then
      log "Checksum validation of rollback successful"
      exit 0
    else
      log "Error: checksum validation of rollback failed"
      exit 1
    fi
  else
    log "Error: rollback of $1 to $target_folder failed"
    exit 1
