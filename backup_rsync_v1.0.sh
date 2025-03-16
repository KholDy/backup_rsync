#!/bin/bash

# backup_rsync.sh v1.0: This script makes a backup copy of your files both locally and to a remote machine.

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
MAGENTA='\033[0;35m'
ENDCOLOR="\e[0m"

PROGNAME="$(basename $0)"
CURRENT_DATE=$(date +%Y-%m-%d)

usage () {
    echo -e "${GREEN}   $PROGNAME${ENDCOLOR}:"
    echo -e "${BLUE}1. If you want to make backup to localhost: "
    echo -e "   usage:${MAGENTA} $PROGNAME <-lb or --localbackup> <source_directory> <target_directory>"
    echo -e "${BLUE}2. If you want to make backup to remote host:"
    echo -e "   usage:${MAGENTA} $PROGNAME <-rb or --remotebackup> <source_directory user@host:<target_directory>"
    echo -e "${BLUE}3. If you want to exclude some files or directories from your backup: "
    echo -e "   usage:${MAGENTA} $PROGNAME <-e or --exclude> <source_directory <target_directory> <list_of_exclude>"
}

if ! command -v rsync > /dev/null 2>&1; then
    echo -e "${YELLOW}This script requires rsync to be installed."
    echo "Please use your distribution's package manager to install it and try again.${ENDCOLOR}"
    exit 2
fi

source_dir=$2
target_dir=$3
log_file_path=${target_dir#*:}/backup_${CURRENT_DATE}.log
list_of_exclude=
rsync_options=

checking_paths () {
    if [[ -z "$source_dir" ]] || [[ -z "$target_dir" ]]; then
        echo -e "${RED}PATH <source_dir> or <target_dir> not set, use $PROGNAME -h to view help.${ENDCOLOR}"
        exit 1
    fi

    if [[ ! "$source_dir" =~ ^/|(/[a-zA-Z0-9_-]+)+$ ]] || [[ ! "$target_dir" =~ ^/|(/[a-zA-Z0-9_-]+)+$ ]]; then
        echo -e "${RED}PATHs are not set correctly, use absolute path.${ENDCOLOR}"
        exit 1
    fi
}

while [ -n "$1" ]; do
    case "$1" in
        -e | --exclude)             checking_paths
                                    list_of_exclude=$4
                                    if [[ -z "$list_of_exclude" ]]; then
                                        echo -e "${RED}PATH to the <list_of_exclude> not set, use $PROGNAME -h to view help.${ENDCOLOR}"
                                        exit 1
                                    elif [[ "$list_of_exclude" =~ ^/?|(/[a-zA-Z0-9_-]+)+$ ]]; then
                                        rsync_options="-avbP --exclude-from=${list_of_exclude} --backup-dir ${target_dir}/${CURRENT_DATE} --delete --log-file=$log_file_path"
                                    fi
                                    break;;
        -lb | --localbackup)        checking_paths
                                    rsync_options="-avbP --backup-dir ${target_dir}/${CURRENT_DATE} --delete --log-file=$log_file_path"
                                    break;;
        -rb | --remotebackup)       if [[ ! "$source_dir" =~ ^/|(/[a-zA-Z0-9_-]+)+$ ]] || [[ ! "$target_dir" =~ ^[A-Za-z][A-Za-z0-9_]{3,15}@(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?):(/[a-zA-Z0-9_-]+)+$ ]]; then
                                        echo -e "${RED}PATHs are not set correctly, use absolute path.${ENDCOLOR}"
                                        exit 1
                                    fi
                                    rsync_options="-avbP --backup-dir ${target_dir}/${CURRENT_DATE} --delete --remote-option=--log-file=$log_file_path"
                                    break;;
        -rbe)                       list_of_exclude=$4
                                    if [[ ! "$source_dir" =~ ^/|(/[a-zA-Z0-9_-]+)+$ ]] || [[ ! "$target_dir" =~ ^[A-Za-z][A-Za-z0-9_]{3,15}@(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?):(/[a-zA-Z0-9_-]+)+$ ]]; then
                                        echo -e "${RED}PATHs are not set correctly, use absolute path.${ENDCOLOR}"
                                        exit 1
                                    fi
                                    rsync_options="-avbP --exclude-from=${list_of_exclude} --backup-dir ${target_dir}/${CURRENT_DATE} --delete --remote-option=--log-file=$log_file_path"
                                    break;;
        -h | --help)                usage
                                    exit;;
        --)                         shift
                                    break;;
        *)                          usage >&2
                                    exit 1;;
    esac
    shift
done

$(which rsync) $rsync_options ${source_dir} ${target_dir}/current  
if [[ $? -eq 0 ]]; then 
    echo -e "${GREEN}Your log file is located ${target_dir}/backup_${CURRENT_DATE}${ENDCOLOR}"
    echo -e "${GREEN}Successfully completed!!!${ENDCOLOR}"
else
    echo -e "${RED}ERROR!!!${ENDCOLOR}" 2>$1
fi
