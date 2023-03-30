Write a bash script named "backup_validate_rollback.sh" in order to backup and rollback a directory. User should provide the source directory.

Basic funcationality:
a) Add input paramater validation check to test user have correctly called the script
b) Add checksum validation test to compare both directories.
c) Create a log file directory in the location of the script. Create a logfile everytime script is run. Logfile should log all errors and successes.


Usage: backup_validate_rollback.sh [-r] <FOLDER>. 

If -r parameter is not included, create a backup folder with "_backup_currentdatetimestamp" subscript added to the input folder name. Run checsum validation test to check backup success. If test is successful, log and provide success exit code. If test failed, log and provide failure exit code. 

If -r parameter is included, then extract the input folder name from the folder paramter by removing the "_backup_currentdatetimestamp" subscript added to the input folder name. Remove this folder. Then rename the input folder by removing the "_backup_currentdatetimestamp" subscript added to the input folder name. Run checsum validation test to check backup success. If test is successful, log and provide success exit code. If test failed, log and provide failure exit code. 



#!/bin/bash

# Check if the script is called with a directory parameter
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-r] <FOLDER>"
    exit 1
fi

# Parse command line options
if [[ $1 == "-r" ]]; then
    rollback=true
    folder=${2%_backup_*}
else
    rollback=false
    folder=$1
fi

# Check if the folder exists
if [[ ! -d $folder ]]; then
    echo "Error: Directory $folder not found"
    exit 1
fi

# Create a backup folder or rollback to the previous version
if [[ $rollback == false ]]; then
    backup_folder="${folder}_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$folder" "$backup_folder"
    if [[ $? -eq 0 ]]; then
        echo "Backup successful: $backup_folder"
        backup_checksum=$(find "$backup_folder" -type f -print0 | xargs -0 sha256sum | sort -k 2 | sha256sum)
    else
        echo "Error: Backup failed"
        exit 1
    fi
else
    backup_folder=$(find "$folder" -maxdepth 1 -type d -name "*_backup_*" | sort -r | head -n 1)
    if [[ -z $backup_folder ]]; then
        echo "Error: Backup folder not found"
        exit 1
    fi
    rm -rf "$folder"
    mv "$backup_folder" "$folder"
    if [[ $? -eq 0 ]]; then
        echo "Rollback successful: $folder"
        backup_checksum=$(find "$folder" -type f -print0 | xargs -0 sha256sum | sort -k 2 | sha256sum)
    else
        echo "Error: Rollback failed"
        exit 1
    fi
fi

# Validate backup or rollback
folder_checksum=$(find "$folder" -type f -print0 | xargs -0 sha256sum | sort -k 2 | sha256sum)
if [[ $backup_checksum == $folder_checksum ]]; then
    echo "Checksum validation successful"
    exit 0
else
    echo "Error: Checksum validation failed"
    exit 1
fi

# Log results to file
log_file="$(dirname $0)/backup_validate_rollback.log"
if [[ -f $log_file ]]; then
    echo "$(date +%Y-%m-%d_%H:%M:%S) $backup_folder $folder_checksum $backup_checksum" >> "$log_file"
else
    echo "$(date +%Y-%m-%d_%H:%M:%S) $backup_folder $folder_checksum $backup_checksum" > "$log_file"
fi
------------------


#!/bin/bash

# Function to print usage information and exit with failure
usage() {
    echo "Usage: backup_validate_rollback.sh [-r] <FOLDER>"
    exit 1
}

# Function to create backup folder and log backup status
backup() {
    # Create backup folder name with current timestamp
    backup_folder="$1_backup_$(date +"%Y%m%d%H%M%S")"
    echo "Creating backup folder: $backup_folder"
    mkdir "$backup_folder"

    # Copy files to backup folder
    cp -r "$1"/* "$backup_folder"

    # Compute md5sum of original folder and backup folder
    md5_original=$(md5sum "$1"/* | awk '{ print $1 }' | md5sum | awk '{ print $1 }')
    md5_backup=$(md5sum "$backup_folder"/* | awk '{ print $1 }' | md5sum | awk '{ print $1 }')

    # Compare md5sums and log status
    if [ "$md5_original" = "$md5_backup" ]; then
        echo "Backup successful: $backup_folder"
        echo "$(date +"%Y-%m-%d %H:%M:%S"): Backup successful for folder: $1" >> "$log_file"
        exit 0
    else
        echo "Backup failed: $backup_folder"
        echo "$(date +"%Y-%m-%d %H:%M:%S"): Backup failed for folder: $1" >> "$log_file"
        exit 1
    fi
}

# Function to rollback folder and log status
rollback() {
    # Extract folder name and backup folder name
    folder=$(echo "$1" | sed 's/_backup_[0-9]\{14\}//')
    backup_folder=$(echo "$1" | sed 's/\(.*\)_backup_[0-9]\{14\}/\1/')

    # Remove current folder and rename backup folder
    echo "Rolling back folder: $folder"
    rm -rf "$folder"
    mv "$backup_folder" "$folder"

    # Compute md5sum of original folder and rolled back folder
    md5_original=$(md5sum "$1"/* | awk '{ print $1 }' | md5sum | awk '{ print $1 }')
    md5_rollback=$(md5sum "$folder"/* | awk '{ print $1 }' | md5sum | awk '{ print $1 }')

    # Compare md5sums and log status
    if [ "$md5_original" = "$md5_rollback" ]; then
        echo "Rollback successful: $folder"
        echo "$(date +"%Y-%m-%d %H:%M:%S"): Rollback successful for folder: $1" >> "$log_file"
        exit 0
    else
        echo "Rollback failed: $folder"
        echo "$(date +"%Y-%m-%d %H:%M:%S"): Rollback failed for folder: $1" >> "$log_file"
        exit 1
    fi
}

# Check input parameters
if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    usage
fi

# Check if -r option is provided
if [ "$1" = "-r" ]; then
    if [ "$#" -ne 2 ]; then
        usage
    fi

    # Check if backup folder exists
    if [ ! -d "$2" ]; then
        echo "Backup folder not found: $















