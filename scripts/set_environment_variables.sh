#!/bin/bash
#
# Set environment variables based on config.ini
#
# Usage
#
#   source set_environment_variables.sh
#

SCRIPT_DIR="$(dirname "$0")"
ETC_DIR="$SCRIPT_DIR/../etc"
CONFIG_FILE="$ETC_DIR/live/config.ini"

set_config_vars() {
    while IFS=' = ' read -r key value
    do
        if [[ $key != \[*] ]]; then
            export $key="$value"
        fi
    done < <(grep -v '^#' $CONFIG_FILE | grep -v '^$')
}

set_config_vars
