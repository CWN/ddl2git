#!/bin/bash

SCRIPT_NAME=`basename $0`
SCRIPT_DIR=$(dirname "$(realpath -s "$0")")
LOGS=$SCRIPT_DIR/logs


# check arguments
ARGS_COUNT=1
if [ $# -ne "$ARGS_COUNT" ]; then
    echo -e "Usage: $SCRIPT_NAME oracle_connect_string"
    echo -e "\nExample: $SCRIPT_NAME user/password@tns_db_name"
    exit 10
fi

ORACLE_CONNECT_STRING=$1
ORACLE_INSTANCE=${ORACLE_CONNECT_STRING##*@}

LOG_TIMESTAMP=`LANG=c date "+%Y%m%d_%H%M%S"`
LOG_FILE="${LOGS}/${ORACLE_INSTANCE}_${LOG_TIMESTAMP}.log"

$SCRIPT_DIR/ddl2git.sh ${ORACLE_CONNECT_STRING} > $LOG_FILE

# send email with logfile
# for example use perl script by Brandon Zehm <caspian@dotconf.net>
# non-official github repo: https://github.com/mogaal/sendemail

# /usr/local/bin/sendEmail -s <mail_server_ip> -f <from@email> -t <to@email> -u "ddl2git export of $ORACLE_INSTANCE on $HOSTNAME finished" -o message-file=$LOG_FILE